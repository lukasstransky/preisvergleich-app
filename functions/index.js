const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const algoliasearch = require('algoliasearch');

initializeApp();

const db = getFirestore();
const ALGOLIA_INDEX = 'products';

/**
 * Runs every hour. Checks all active price alerts and sends FCM notifications
 * when conditions are met. Supports both product-level and keyword-level alerts.
 */
exports.checkPriceAlerts = onSchedule(
  {
    schedule: 'every 60 minutes',
    timeZone: 'Europe/Vienna',
    secrets: ['ALGOLIA_APP_ID', 'ALGOLIA_API_KEY'],
    memory: '256MiB',
  },
  async () => {
    const algoliaClient = algoliasearch(
      process.env.ALGOLIA_APP_ID,
      process.env.ALGOLIA_API_KEY
    );
    const index = algoliaClient.initIndex(ALGOLIA_INDEX);

    const alertsSnapshot = await db
      .collection('price_alerts')
      .where('active', '==', true)
      .get();

    if (alertsSnapshot.empty) return;

    const messaging = getMessaging();
    const batch = db.batch();
    const notifications = [];

    for (const doc of alertsSnapshot.docs) {
      const alert = doc.data();
      const isKeywordAlert = alert.scope === 'keyword';

      if (isKeywordAlert) {
        await _handleKeywordAlert(doc, alert, index, batch, notifications);
      } else {
        await _handleProductAlert(doc, alert, index, batch, notifications);
      }
    }

    if (notifications.length > 0) {
      await batch.commit();
      for (let i = 0; i < notifications.length; i += 500) {
        const chunk = notifications.slice(i, i + 500);
        console.log(`Sending ${chunk.length} notifications, tokens: ${chunk.map(n => n.token?.substring(0, 12) + '...').join(', ')}`);
        const response = await messaging.sendEach(chunk);
        console.log(`Sent ${response.successCount}/${chunk.length} notifications`);
        for (const result of response.responses) {
          if (!result.success) {
            console.error(`FCM error: code=${result.error?.code} msg=${result.error?.message}`);
          } else {
            console.log(`FCM success: messageId=${result.messageId}`);
          }
        }
      }
    }

    console.log(`Alert check complete. Triggered ${notifications.length} notifications.`);
  }
);

async function _handleProductAlert(doc, alert, index, batch, notifications) {
  let product;
  try {
    product = await index.getObject(alert.productId, {
      attributesToRetrieve: ['price', 'inPromotion', 'name'],
    });
  } catch {
    return; // product no longer in index
  }

  const triggered = _checkCondition(alert, product.price, product.inPromotion === true);
  if (!triggered) return;
  if (_recentlyTriggered(alert)) return;

  notifications.push(_buildNotification(
    alert.deviceToken,
    triggered.title,
    triggered.body,
    { productId: alert.productId, alertId: doc.id }
  ));

  batch.update(doc.ref, {
    lastTriggered: FieldValue.serverTimestamp(),
    currentPrice: product.price,
  });
}

async function _handleKeywordAlert(doc, alert, index, batch, notifications) {
  if (_recentlyTriggered(alert)) return;

  // Build filter based on alert type
  let filters = '';
  if (alert.alertType === 'promotion') {
    filters = 'inPromotion:true';
  } else if (alert.alertType === 'target_price' && alert.targetPrice != null) {
    filters = `price <= ${alert.targetPrice}`;
  }

  const result = await index.search(alert.keyword, {
    filters,
    hitsPerPage: 5,
    attributesToRetrieve: ['name', 'price', 'supermarket'],
  });

  if (result.hits.length === 0) return;

  const productList = result.hits
    .slice(0, 3)
    .map(h => `${h.name} – €${Number(h.price).toFixed(2)} (${_capitalize(h.supermarket)})`)
    .join('\n');

  const body = alert.alertType === 'promotion'
    ? `${result.hits.length} Angebote gefunden:\n${productList}`
    : `${result.hits.length} Produkte unter €${Number(alert.targetPrice).toFixed(2)}:\n${productList}`;

  notifications.push(_buildNotification(
    alert.deviceToken,
    `🔔 "${alert.keyword}" – Preisalarm`,
    body,
    { keyword: alert.keyword, alertId: doc.id }
  ));

  batch.update(doc.ref, { lastTriggered: FieldValue.serverTimestamp() });
}

function _checkCondition(alert, currentPrice, inPromotion) {
  if (alert.alertType === 'promotion' && inPromotion) {
    return {
      title: '🔔 Preisalarm',
      body: `${alert.productName} ist jetzt im Angebot für €${currentPrice.toFixed(2)}!`,
    };
  }
  if (alert.alertType === 'target_price' && alert.targetPrice != null && currentPrice <= alert.targetPrice) {
    return {
      title: '🔔 Preisalarm',
      body: `${alert.productName} kostet jetzt €${currentPrice.toFixed(2)} – unter deinem Ziel von €${Number(alert.targetPrice).toFixed(2)}!`,
    };
  }
  return null;
}

function _recentlyTriggered(alert) {
  if (!alert.lastTriggered) return false;
  const last = alert.lastTriggered.toDate();
  const hoursSince = (Date.now() - last.getTime()) / (1000 * 60 * 60);
  return hoursSince < 24;
}

function _buildNotification(token, title, body, data) {
  return {
    token,
    notification: { title, body },
    data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
    apns: { payload: { aps: { sound: 'default' } } },
  };
}

function _capitalize(str) {
  return str ? str.charAt(0).toUpperCase() + str.slice(1) : str;
}
