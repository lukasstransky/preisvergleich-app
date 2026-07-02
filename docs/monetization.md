# Monetarisierung (Freemium)

Dieses Dokument beschreibt das eingebaute Freemium-Gerüst und wie es scharf
geschaltet wird.

## Modell

Freemium mit Abo. Kernnutzen (Suche & Preisvergleich) bleibt frei; die
kostenintensiven und bindungsstarken Features werden im Free-Tier limitiert:

| Feature            | Free                        | Premium     |
| ------------------ | --------------------------- | ----------- |
| Suche & Vergleich  | unbegrenzt                  | unbegrenzt  |
| Preisalarme        | `freeAlertLimit` (Std. 3)   | unbegrenzt  |
| Preisverlauf       | `priceHistoryFreeDays` (7)  | voll        |
| Einkaufslisten     | `freeListLimit` (Std. 1)    | unbegrenzt  |
| Werbung            | (optional)                  | keine       |

## Zwei-Phasen-Rollout

Alles ist **standardmäßig deaktiviert** (`monetizationEnabled = false`). Bei
einem frischen Install und in allen Tests ist nichts limitiert — Verhalten wie
bisher. So kann wachstumsfreundlich gelauncht werden.

Sobald genug Nutzer/Retention da sind, wird Monetarisierung **ohne App-Update**
scharf geschaltet, indem in Firestore das Doc `config/monetization` gesetzt wird:

```json
{
  "monetizationEnabled": true,
  "freeAlertLimit": 3,
  "freeListLimit": 1,
  "priceHistoryFreeDays": 7
}
```

Der Client liest diese Config bei `AppState.initialize()`; die Cloud Function
liest sie bei jedem Lauf.

## Entitlement (wer ist Premium)

Single Source of Truth ist das Doc `entitlements/{uid}`:

```json
{ "active": true, "expiresAt": <Timestamp>, "productId": "premium_yearly" }
```

- **Nur der Server schreibt** dieses Doc (RevenueCat-Webhook via Admin SDK).
  Firestore-Rules verbieten Client-Writes (`firestore.rules`), damit Premium
  nicht durch einen manipulierten Client gefälscht werden kann.
- Der Client **liest** es (live via Stream in `PremiumService`).

## Serverseitige Durchsetzung

Selbst wenn ein manipulierter Client das Client-Limit umgeht und mehr Alarme
schreibt, wertet die Cloud Function (`functions/index.js`, `_applyTierLimits`)
für Nicht-Premium-Nutzer nur die `freeAlertLimit` neuesten Alarme aus. Das
deckelt die Algolia-/FCM-Kosten unabhängig vom Client.

## RevenueCat anbinden (Kauf-Flow)

Das Lesen des Entitlements braucht RevenueCat **nicht** (läuft über Firestore).
RevenueCat wird nur für den Kauf-Flow und das serverseitige Setzen des
Entitlements gebraucht:

1. `flutter pub add purchases_flutter` (Zeile in `pubspec.yaml` ist vorbereitet).
2. In `lib/main.dart` `Purchases.configure(...)` mit dem RevenueCat Public Key.
3. In `lib/services/premium_service.dart` die `TODO(revenuecat)`-Stellen in
   `startPurchase()` / `restorePurchases()` ausfüllen.
4. RevenueCat-Webhook → Cloud Function anlegen, die bei Kauf/Erneuerung/Ablauf
   `entitlements/{uid}` schreibt (`active`, `expiresAt`, `productId`).
5. Produkte/Entitlement `premium` im RevenueCat-Dashboard + App Store Connect /
   Play Console anlegen.

## Testen ohne Store

Im Debug-Build schaltet der „Premium freischalten“-Button im Paywall-Sheet
Premium lokal frei (`PremiumService.setDebugPremium`), sodass Gating und Paywall
ohne konfigurierten Store getestet werden können.

## Offene To-dos (Reihenfolge = empfohlene Reihenfolge)

Was bereits erledigt ist: Client-Gating (Alarme, Listen, Preisverlauf-Getter),
Paywall-UI, Profil-Upsell + Restore-Button, serverseitige Kostenbremse
(`_applyTierLimits`), Firestore-Rules (Entitlement/Config server-only),
Remote-Config-Schalter, Unit-Tests.

### A. Store-Produkte anlegen (Voraussetzung für alles Weitere)

- [ ] **App Store Connect**: Auto-erneuerbares Abo anlegen, z. B.
      `premium_monthly` (~2,49 €) und `premium_yearly` (~14,99 €) in einer
      Subscription-Group. Lokalisierte Namen/Beschreibung + Review-Screenshot.
- [ ] **Google Play Console**: dieselben Abo-Produkte anlegen.
- [ ] Steuer-/Bankdaten in beiden Stores hinterlegen (sonst keine Auszahlung).

### B. RevenueCat verbinden

- [ ] RevenueCat-Projekt anlegen, App Store + Play Store verknüpfen (App-Specific
      Shared Secret bzw. Service-Account-JSON hinterlegen).
- [ ] Entitlement `premium` anlegen und beide Store-Produkte darauf mappen;
      ein „current“ Offering mit den Packages definieren.
- [ ] `flutter pub add purchases_flutter` (Zeile in `pubspec.yaml` ist vorbereitet,
      nur einkommentieren/ausführen).
- [ ] `Purchases.configure(...)` mit dem RevenueCat **Public** SDK Key in
      `lib/main.dart` (TODO(revenuecat)-Marker).
- [ ] `startPurchase()` / `restorePurchases()` in
      `lib/services/premium_service.dart` mit echten SDK-Calls füllen
      (TODO(revenuecat)-Marker; Beispielcode steht im Kommentar).

### C. Entitlement serverseitig setzen

- [ ] Cloud Function für den **RevenueCat-Webhook** anlegen (HTTP-Trigger), die
      bei `INITIAL_PURCHASE` / `RENEWAL` / `CANCELLATION` / `EXPIRATION`
      `entitlements/{uid}` schreibt: `{ active, expiresAt, productId, updatedAt }`.
      Die `app_user_id` im Webhook = Firebase-UID (RevenueCat mit
      `Purchases.logIn(uid)` an die UID koppeln).
- [ ] Webhook-Secret prüfen (Authorization-Header), damit niemand Fremdrequests
      schickt.
- [ ] Firestore-Rules deployen: `firebase deploy --only firestore:rules`.

### D. Scharfschalten (wenn Retention da ist)

- [ ] Firestore-Doc `config/monetization` setzen:
      `{ monetizationEnabled: true, freeAlertLimit: 3, freeListLimit: 1,
      priceHistoryFreeDays: 7 }`. Kein App-Update nötig.
- [ ] Auf Testgerät verifizieren: Free-Limit greift, Kauf schaltet frei, Restore
      funktioniert, Cloud Function wertet nur die erlaubten Alarme aus.

### E. Offene Produkt-Details (optional / später)

- [ ] **Preisverlauf-Chart** an das Limit koppeln: `AppState.priceHistoryVisibleDays`
      wird bereitgestellt, aber `lib/widgets/price_history_chart.dart` filtert noch
      nicht danach (Free = nur letzte X Tage, Rest ausgegraut + Upsell-Hinweis).
- [ ] **Werbung** als zweite Einnahmequelle im Free-Tier (`google_mobile_ads`),
      dezent unter den Suchergebnissen; für Premium ausblenden.
- [ ] **Onboarding/Upsell-Timing** festlegen (z. B. Paywall nicht beim ersten
      Alarm, sondern erst beim Überschreiten des Limits — so ist es aktuell).
- [ ] **Analytics** auf `PremiumRequiredException.feature` + Paywall-Views /
      Käufe, um die Conversion zu messen und Limits zu justieren.

### F. Pflicht für den App-Store-Review

- [ ] Abo-Bedingungen (Preis, Laufzeit, Auto-Renew), Links zu **Datenschutz** und
      **Nutzungsbedingungen** im Paywall-Sheet ergänzen — Apple lehnt Abos ohne
      diese Angaben ab.
- [ ] „Kauf wiederherstellen“ ist bereits im Profil + Paywall vorhanden (erfüllt
      Apples Restore-Pflicht).
