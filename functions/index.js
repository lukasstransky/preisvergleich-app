const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const algoliasearch = require('algoliasearch');

initializeApp();

const db = getFirestore();
const ALGOLIA_INDEX = 'products';

/**
 * Runs once a day at 11:00 (Europe/Vienna). Checks all active price alerts and
 * sends FCM notifications when conditions are met. Supports both product-level
 * and keyword-level alerts.
 *
 * Daily (not hourly) because the source data is only refreshed once a day by the
 * morning scrapers — prices cannot change in between, so more frequent checks
 * would just burn Algolia search requests for no benefit. 11:00 is chosen for
 * notification delivery: high open rates around lunch, and the whole rest of the
 * day for the user to act on a deal before shops close.
 */
exports.checkPriceAlerts = onSchedule(
  {
    schedule: 'every day 11:00',
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

    // Always commit: handlers also record state changes (e.g. tracked product
    // sets, condition resets) that must persist even when no notification fires.
    // Committing an empty batch is a harmless no-op.
    await batch.commit();

    if (notifications.length > 0) {
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
      { productId: alert.productId, productName: alert.productName, alertId: doc.id, alertType: alert.alertType }
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
    hitsPerPage: 50,
    attributesToRetrieve: ['objectID'],
  });

  // Products that currently match the alert (on offer / under target price).
  const currentIds = result.hits.map((h) => h.objectID);
  // Products we already notified about on a previous run.
  const previousSet = new Set(
    Array.isArray(alert.notifiedProductIds) ? alert.notifiedProductIds : []
  );

  // Only notify for products that are newly matching — not ones we already
  // reported. This avoids re-notifying for a broad category (e.g. "wodka")
  // where there is almost always *some* product on offer.
  const newIds = currentIds.filter((id) => !previousSet.has(id));

  // Did the tracked set change at all? We persist the current set even without
  // a notification so a product that drops out and later returns counts as new
  // again. (currentIds shorter, or membership differs.)
  const setChanged =
    currentIds.length !== previousSet.size ||
    currentIds.some((id) => !previousSet.has(id));

  if (newIds.length > 0) {
    // A keyword can match many products and hits are ranked by relevance, not
    // price — so we report the count of new matches rather than one hit's price
    // (that would imply a precision we don't have). The target price we quote is
    // the user's own value, which is always accurate.
    const count = newIds.length;
    let title;
    let body;
    if (alert.alertType === 'promotion') {
      title = '🔥 Neues Angebot!';
      body = count === 1
        ? `Ein neuer Treffer für "${alert.keyword}" ist im Angebot 🛒`
        : `${count} neue Angebote für "${alert.keyword}" 🛒`;
    } else {
      title = '🎯 Zielpreis erreicht!';
      body = count === 1
        ? `Ein neuer Treffer für "${alert.keyword}" liegt unter ${_formatPrice(alert.targetPrice)} 💶`
        : `${count} neue Treffer für "${alert.keyword}" unter ${_formatPrice(alert.targetPrice)} 💶`;
    }

    const data = { keyword: alert.keyword, alertId: doc.id, alertType: alert.alertType };
    if (alert.category) data.category = alert.category;

    notifications.push(_buildNotification(
      alert.deviceToken,
      title,
      body,
      data
    ));
    batch.update(doc.ref, {
      notifiedProductIds: currentIds,
      lastTriggered: FieldValue.serverTimestamp(),
    });
  } else if (setChanged) {
    // No new matches, but some offers ended → keep the tracked set in sync so
    // returning offers are treated as new later. No notification.
    batch.update(doc.ref, { notifiedProductIds: currentIds });
  }
}

function _checkCondition(alert, currentPrice, inPromotion) {
  if (alert.alertType === 'promotion' && inPromotion) {
    return {
      title: '🔥 Jetzt im Angebot!',
      body: `${alert.productName} ist reduziert – jetzt für ${_formatPrice(currentPrice)} 🛒`,
    };
  }
  if (alert.alertType === 'target_price' && alert.targetPrice != null && currentPrice <= alert.targetPrice) {
    return {
      title: '🎯 Zielpreis erreicht!',
      body: `${alert.productName} kostet jetzt nur ${_formatPrice(currentPrice)} 💶`,
    };
  }
  return null;
}

// Formats a numeric price as an Austrian/German euro string, e.g. 3.5 → "€3,50".
function _formatPrice(value) {
  return `€${Number(value).toFixed(2).replace('.', ',')}`;
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
