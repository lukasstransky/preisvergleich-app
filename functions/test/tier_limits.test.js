const { test } = require('node:test');
const assert = require('node:assert');

const { _applyTierLimits } = require('../index');

// ── Fakes ────────────────────────────────────────────────────────────────────

/** Builds a fake alert document as returned by a Firestore query snapshot. */
function alertDoc(id, { userId, createdAtMillis = 0 } = {}) {
  return {
    id,
    ref: { id },
    data: () => ({
      userId,
      createdAt: { toMillis: () => createdAtMillis },
    }),
  };
}

function snapshot(data) {
  return { exists: data != null, data: () => data };
}

/**
 * Fake Firestore that only implements the two lookups `_applyTierLimits` does:
 * `config/monetization` and `entitlements/{uid}`.
 */
function fakeDb({ config, entitlements = {} }) {
  return {
    collection(name) {
      return {
        doc(id) {
          return {
            get: async () => {
              if (name === 'config') return snapshot(config);
              if (name === 'entitlements') return snapshot(entitlements[id]);
              return snapshot(undefined);
            },
          };
        },
      };
    },
  };
}

const ids = (docs) => docs.map((d) => d.id).sort();

// ── Tests ────────────────────────────────────────────────────────────────────

test('monetization disabled → every alert passes through', async () => {
  const docs = [
    alertDoc('a1', { userId: 'u1' }),
    alertDoc('a2', { userId: 'u1' }),
    alertDoc('a3', { userId: 'u1' }),
  ];
  const db = fakeDb({ config: { monetizationEnabled: false, freeAlertLimit: 1 } });

  const result = await _applyTierLimits(docs, db);

  assert.deepStrictEqual(ids(result), ['a1', 'a2', 'a3']);
});

test('missing config doc → treated as disabled, all pass', async () => {
  const docs = [alertDoc('a1', { userId: 'u1' }), alertDoc('a2', { userId: 'u1' })];
  const db = fakeDb({ config: undefined });

  const result = await _applyTierLimits(docs, db);

  assert.deepStrictEqual(ids(result), ['a1', 'a2']);
});

test('free user → only the N newest alerts are kept', async () => {
  const docs = [
    alertDoc('old', { userId: 'u1', createdAtMillis: 100 }),
    alertDoc('mid', { userId: 'u1', createdAtMillis: 200 }),
    alertDoc('new', { userId: 'u1', createdAtMillis: 300 }),
  ];
  const db = fakeDb({ config: { monetizationEnabled: true, freeAlertLimit: 2 } });

  const result = await _applyTierLimits(docs, db);

  assert.deepStrictEqual(ids(result), ['mid', 'new']); // 'old' dropped
});

test('freeAlertLimit defaults to 3 when unset', async () => {
  const docs = [1, 2, 3, 4].map((n) =>
    alertDoc(`a${n}`, { userId: 'u1', createdAtMillis: n }));
  const db = fakeDb({ config: { monetizationEnabled: true } });

  const result = await _applyTierLimits(docs, db);

  assert.strictEqual(result.length, 3);
  assert.deepStrictEqual(ids(result), ['a2', 'a3', 'a4']); // newest three
});

test('premium user → all their alerts pass, ignoring the limit', async () => {
  const docs = [
    alertDoc('a1', { userId: 'u1' }),
    alertDoc('a2', { userId: 'u1' }),
    alertDoc('a3', { userId: 'u1' }),
  ];
  const db = fakeDb({
    config: { monetizationEnabled: true, freeAlertLimit: 1 },
    entitlements: { u1: { active: true } },
  });

  const result = await _applyTierLimits(docs, db);

  assert.deepStrictEqual(ids(result), ['a1', 'a2', 'a3']);
});

test('expired entitlement → user is treated as free', async () => {
  const docs = [
    alertDoc('a1', { userId: 'u1', createdAtMillis: 1 }),
    alertDoc('a2', { userId: 'u1', createdAtMillis: 2 }),
  ];
  const yesterday = new Date(Date.now() - 86_400_000);
  const db = fakeDb({
    config: { monetizationEnabled: true, freeAlertLimit: 1 },
    entitlements: { u1: { active: true, expiresAt: { toDate: () => yesterday } } },
  });

  const result = await _applyTierLimits(docs, db);

  assert.deepStrictEqual(ids(result), ['a2']); // capped to newest one
});

test('legacy alerts without userId are grandfathered in', async () => {
  const docs = [
    alertDoc('legacy1', { userId: undefined }),
    alertDoc('legacy2', { userId: undefined }),
    alertDoc('u1a', { userId: 'u1', createdAtMillis: 1 }),
    alertDoc('u1b', { userId: 'u1', createdAtMillis: 2 }),
  ];
  const db = fakeDb({ config: { monetizationEnabled: true, freeAlertLimit: 1 } });

  const result = await _applyTierLimits(docs, db);

  assert.deepStrictEqual(ids(result), ['legacy1', 'legacy2', 'u1b']);
});

test('per-user limits are independent', async () => {
  const docs = [
    alertDoc('u1a', { userId: 'u1', createdAtMillis: 1 }),
    alertDoc('u1b', { userId: 'u1', createdAtMillis: 2 }),
    alertDoc('u2a', { userId: 'u2', createdAtMillis: 1 }),
    alertDoc('u2b', { userId: 'u2', createdAtMillis: 2 }),
  ];
  const db = fakeDb({
    config: { monetizationEnabled: true, freeAlertLimit: 1 },
    entitlements: { u2: { active: true } }, // u2 premium, u1 free
  });

  const result = await _applyTierLimits(docs, db);

  assert.deepStrictEqual(ids(result), ['u1b', 'u2a', 'u2b']);
});
