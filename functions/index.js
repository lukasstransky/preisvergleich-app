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

    // Enforce the free-tier alert limit server-side so a modified client cannot
    // create unlimited alerts and drive up Algolia/FCM cost. Non-premium users
    // only ever get their N most recent alerts evaluated.
    const eligibleDocs = await _applyTierLimits(alertsSnapshot.docs);

    const messaging = getMessaging();
    const batch = db.batch();
    const notifications = [];

    for (const doc of eligibleDocs) {
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

/**
 * Filters the active alerts down to the ones that should actually be evaluated,
 * enforcing the free-tier limit for non-premium users.
 *
 * - While monetization is disabled (soft launch) every alert is eligible.
 * - Legacy alerts without a `userId` are grandfathered in (always eligible).
 * - Otherwise, for each user we look up `entitlements/{uid}`; premium users are
 *   unlimited, everyone else keeps only their `freeAlertLimit` most recent alerts.
 */
async function _applyTierLimits(docs, database = db) {
  const configSnap = await database.collection('config').doc('monetization').get();
  const config = configSnap.exists ? configSnap.data() : {};
  if (config.monetizationEnabled !== true) return docs;
  const freeAlertLimit =
    typeof config.freeAlertLimit === 'number' ? config.freeAlertLimit : 3;

  const byUser = new Map();
  const eligible = [];
  for (const doc of docs) {
    const uid = doc.data().userId;
    if (!uid) {
      eligible.push(doc); // legacy alert, grandfathered
      continue;
    }
    if (!byUser.has(uid)) byUser.set(uid, []);
    byUser.get(uid).push(doc);
  }

  for (const [uid, userDocs] of byUser) {
    let premium = false;
    try {
      const ent = await database.collection('entitlements').doc(uid).get();
      const data = ent.exists ? ent.data() : null;
      premium = data?.active === true &&
        (!data.expiresAt || data.expiresAt.toDate() > new Date());
    } catch (e) {
      console.error(`entitlement lookup failed for ${uid}: ${e.message}`);
    }

    if (premium) {
      eligible.push(...userDocs);
      continue;
    }
    // Keep the most recently created alerts up to the free limit.
    userDocs.sort((a, b) => {
      const ta = a.data().createdAt?.toMillis?.() ?? 0;
      const tb = b.data().createdAt?.toMillis?.() ?? 0;
      return tb - ta;
    });
    eligible.push(...userDocs.slice(0, freeAlertLimit));
  }

  return eligible;
}

async function _handleProductAlert(doc, alert, index, batch, notifications) {
  let product;
  try {
    product = await index.getObject(alert.productId, {
      attributesToRetrieve: ['price', 'inPromotion', 'name'],
    });
  } catch {
    return; // product no longer in index
  }

  const conditionNowMet = _checkCondition(alert, product.price, product.inPromotion === true);
  const wasConditionMet = alert.conditionMet === true;

  if (conditionNowMet && !wasConditionMet) {
    // Condition newly became true → notify
    notifications.push(_buildNotification(
      alert.deviceToken,
      conditionNowMet.title,
      conditionNowMet.body,
      { productId: alert.productId, alertId: doc.id }
    ));
    batch.update(doc.ref, {
      conditionMet: true,
      lastTriggered: FieldValue.serverTimestamp(),
      currentPrice: product.price,
    });
  } else if (!conditionNowMet && wasConditionMet) {
    // Condition no longer met → reset so next trigger fires again
    batch.update(doc.ref, { conditionMet: false });
  }
}

async function _handleKeywordAlert(doc, alert, index, batch, notifications) {
  let filters = '';
  if (alert.alertType === 'promotion') {
    filters = 'inPromotion:true';
  } else if (alert.alertType === 'target_price' && alert.targetPrice != null) {
    filters = `price <= ${alert.targetPrice}`;
  }

  const facetFilters = alert.category
    ? [[`normalizedCategory:${alert.category}`]]
    : undefined;

  const result = await index.search(alert.keyword, {
    filters,
    facetFilters,
    hitsPerPage: 5,
    attributesToRetrieve: ['name', 'price', 'supermarket'],
  });

  const conditionNowMet = result.hits.length > 0;
  const wasConditionMet = alert.conditionMet === true;

  if (conditionNowMet && !wasConditionMet) {
    // Condition newly became true → notify
    const best = result.hits[0];
    const bestPrice = `€${Number(best.price).toFixed(2)} (${_capitalize(best.supermarket)})`;
    const more = result.hits.length > 1 ? ` · +${result.hits.length - 1} weitere` : '';

    const body = alert.alertType === 'promotion'
      ? `${result.hits.length} Angebote · ab ${bestPrice}${more}`
      : `${result.hits.length} Produkte unter €${Number(alert.targetPrice).toFixed(2)} · ab ${bestPrice}${more}`;

    notifications.push(_buildNotification(
      alert.deviceToken,
      `🔔 "${alert.keyword}" – Preisalarm`,
      body,
      { keyword: alert.keyword, alertId: doc.id }
    ));
    batch.update(doc.ref, {
      conditionMet: true,
      lastTriggered: FieldValue.serverTimestamp(),
    });
  } else if (!conditionNowMet && wasConditionMet) {
    // No more matching results → reset
    batch.update(doc.ref, { conditionMet: false });
  }
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

// Exported for unit testing (see functions/test/tier_limits.test.js).
exports._applyTierLimits = _applyTierLimits;
