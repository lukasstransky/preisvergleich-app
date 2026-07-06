# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## General Rules

- **Never commit automatically.** Always ask the user before creating a git commit.

## Commands

```bash
# Run on connected iPhone
flutter run --release

# Run unit tests
flutter test

# Run a single test file
flutter test test/providers/app_state_test.dart

# Run integration tests (requires connected device/simulator)
flutter test integration_test/shopping_list_test.dart

# Deploy Firestore security rules
firebase deploy --only firestore:rules

# Deploy Cloud Functions
firebase deploy --only functions
```

## Architecture

This is a Flutter price-comparison app for Austrian supermarkets (Billa, Spar, Hofer, Penny, Lidl, MPreis). The data pipeline is: external scrapers → Algolia (search index) + Firestore (price alerts, user data).

### State management

A single `AppState` (Provider/ChangeNotifier) owns all runtime state: search results, shopping lists, favorites, and price alerts. It is created once in `main.dart` and accessed via `context.read/watch<AppState>()`. All services are injected into `AppState` via constructor parameters — this is the test seam: tests pass fake/mock implementations.

### Data persistence

| Data | Storage | Path |
|---|---|---|
| Shopping lists | Firestore | `users/{uid}/shopping_lists/{listId}` |
| Favorites | Firestore | `users/{uid}/data/favorites` |
| Price alerts | Firestore | `price_alerts/{alertId}` (with `userId` + `deviceToken` fields) |
| Search history | SharedPreferences | local only |
| Active list ID | Firestore | `users/{uid}/settings/data` |

### Authentication (Lazy Auth)

Users are silently signed in anonymously on first launch (`main.dart`). No login screen is shown unless the user initiates it from the Profile tab. Anonymous UIDs persist across app restarts but not reinstalls. `AuthService` uses `linkWithCredential()` (not `signInWithCredential`) when an anonymous user connects a Google/Apple account, preserving their existing Firestore data under the same UID.

`AppState` subscribes to `FirebaseAuth.authStateChanges()` and re-calls `initialize()` when the UID changes (e.g. sign-out → new anonymous session). The `authChanges` and `getUid` constructor params exist solely for test injection.

### Services

- `AlgoliaService` — product search; abstract base `AlgoliaServiceBase` allows mock injection
- `ShoppingListService` / `FavoritesService` — Firestore-backed; accept `FirebaseFirestore` and `String Function()` getUid for test injection
- `PriceAlertService` — Firestore-backed; also stores FCM `deviceToken` on each alert for the Cloud Function to deliver push notifications
- `SearchHistoryService` — SharedPreferences only
- `AuthService` — wraps Firebase Auth + Google/Apple sign-in

### Cloud Function

`functions/index.js` runs every 60 minutes (`checkPriceAlerts`). It reads active price alerts from Firestore, queries Algolia for current prices, and sends FCM push notifications when alert conditions are met. Uses secrets `ALGOLIA_APP_ID` and `ALGOLIA_API_KEY`.

### Theming

`AppColors` is a `ThemeExtension<AppColors>` registered on both light and dark `ThemeData` in `main.dart`. Access via `AppColors.of(context)`. Supermarket brand colors live in `AppColors.supermarket(name)`.

### Testing

Unit tests use `FakeFirebaseFirestore` (from `fake_cloud_firestore`) and inject `authChanges: () => const Stream.empty()` and `getUid: () => 'test-uid'` into `AppState`. Integration tests use `pumpTestApp()` from `integration_test/helpers/pump_app.dart`, which wires up the same fakes. `MockAlgoliaService` and `MockPriceAlertService` live in `integration_test/helpers/`.

**When to write which kind of test:**
- New service method or `AppState` logic → unit test
- New screen or significant UI change that touches navigation or cross-tab state → integration test via `pumpTestApp()`
- Pure widget with no Firebase/state dependency → widget test is fine

**`AuthService` uses lazy getters** (`FirebaseAuth get _auth => FirebaseAuth.instance`) intentionally. Do not convert them back to eager field initializers. `MainScreen` uses `IndexedStack` which mounts all tabs at once — an eager `FirebaseAuth.instance` in `AuthService` crashes integration tests because Firebase is not initialized in that environment.

### Documentation

The `docs/` folder contains feature-level documentation that cannot be derived from reading the code alone. When adding or changing a significant feature, update or create the relevant doc:

- New analytics events → update `docs/analytics.md` (which events fire, when, what parameters)
- Monetization changes → update `docs/monetization.md`
- Any other cross-cutting feature (auth flow, push notifications, etc.) → create a matching `docs/<feature>.md`

Document the **when** and **why**, not the what — the code already shows the what.
