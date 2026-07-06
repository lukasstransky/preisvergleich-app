# Price Alerts

## End-to-End Ablauf

```
User erstellt Alarm  →  Firestore (price_alerts/{id})
                                  ↓
                      Cloud Function (alle 60 min)
                        liest Alarme aus Firestore
                        fragt aktuelle Preise via Algolia ab
                        schickt FCM Push wenn Bedingung erfüllt
                                  ↓
                           User-Gerät (Push Notification)
```

## Alarm-Typen

| Typ | Wann wird ausgelöst |
|---|---|
| `promotion` | Produkt ist im Angebot |
| `targetPrice` | Preis fällt unter einen gesetzten Zielpreis |

Beide Typen gibt es als **Produkt-Alarm** (spezifisches Produkt) und **Keyword-Alarm** (alle Produkte die auf ein Stichwort matchen).

## Wann eine Push feuert (Trigger-Verhalten)

Die Function prüft stündlich, benachrichtigt aber **nicht** jede Stunde erneut, solange die Bedingung erfüllt bleibt — sonst käme bei einem dauerhaften Angebot jede Stunde dieselbe Push. Zwei unterschiedliche Mechanismen:

- **Produkt-Alarm** — Flanken-Logik über das Bool `conditionMet`. Push nur beim Übergang *nicht erfüllt → erfüllt*. Fällt die Bedingung weg (Angebot vorbei / Preis wieder über Zielpreis), wird `conditionMet` zurückgesetzt und der nächste Übergang feuert erneut.

- **Keyword-Alarm** — Diff über die Menge der matchenden Produkt-IDs (`notifiedProductIds`). Push nur für Produkte, die **neu** hinzukommen. Grund: Bei breiten Keywords/Kategorien (z.B. „wodka") ist fast immer *irgendein* Produkt im Angebot; eine reine „gibt es Treffer?"-Flanke würde nur ein einziges Mal feuern und danach nie wieder. Die getrackte Menge wird jeden Lauf durch die aktuell matchende ersetzt — dadurch zählt ein Produkt, das aus dem Angebot fällt und später zurückkommt, wieder als neu. Die Push nennt die Anzahl neuer Treffer (kein Einzelpreis, da Keyword-Treffer nach Relevanz, nicht nach Preis sortiert sind).

`lastTriggered` ist entsprechend „zuletzt benachrichtigt", **nicht** „zuletzt geprüft" — es wird nur bei einer tatsächlich versendeten Push gesetzt.

## Firestore-Struktur

```
price_alerts/{alertId}
  productId, productName, supermarket, currentPrice
  alertType: "promotion" | "targetPrice"
  targetPrice: number | null
  scope: "product" | "keyword"
  keyword: string | null
  userId: string          ← für Cross-Device-Sync
  deviceToken: string     ← FCM-Token des Geräts das den Alarm erstellt hat
  active: bool
  createdAt: Timestamp
  conditionMet: bool          ← nur Produkt-Alarm: Flanken-Status (siehe Trigger-Verhalten)
  notifiedProductIds: string[] ← nur Keyword-Alarm: zuletzt gemeldete matchende Produkt-IDs
  lastTriggered: Timestamp    ← Zeitpunkt der letzten versendeten Push
```

`userId` wird beim Erstellen gesetzt (`FirebaseAuth.instance.currentUser?.uid`). Damit kann ein User seine Alarme auf mehreren Geräten sehen. Legacy-Alarme ohne `userId` werden per `deviceToken` abgefragt (Fallback).

## Cloud Function

`functions/index.js` → `checkPriceAlerts`, läuft jede Stunde via Cloud Scheduler.

Wichtig: Für Free-Tier-User wertet die Function nur die `freeAlertLimit` neuesten Alarme aus (`_applyTierLimits`), unabhängig davon wie viele der Client gespeichert hat. Das begrenzt Algolia- und FCM-Kosten serverseitig.

Benötigte Secrets (Firebase Secret Manager): `ALGOLIA_APP_ID`, `ALGOLIA_API_KEY`.

## FCM Setup

Das `deviceToken` wird beim Erstellen eines Alarms via `firebase_messaging` geholt. Die Funktion `getDeviceToken()` in `PriceAlertService` holt den Token und fragt dabei gleichzeitig die Notification-Permission an (nur beim ersten Mal).
