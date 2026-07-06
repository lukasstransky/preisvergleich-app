# Analytics

Events werden über Firebase Analytics erfasst (`firebase_analytics: ^11.3.0`).  
Die Implementierung liegt in [lib/services/analytics_service.dart](../lib/services/analytics_service.dart), der Aufruf erfolgt in [lib/providers/app_state.dart](../lib/providers/app_state.dart).

---

## Events

### `search` (Firebase Standard-Event)

| Wann | Bedingung |
|---|---|
| Nach jeder erfolgreichen Suche | Query ist nicht leer und Algolia hat geantwortet |

Parameter:
- `search_term` — der eingegebene Suchbegriff (getrimmt)

---

### `search_performed` (Custom-Event)

Ergänzt das Firebase-Standard-`search` um die Trefferzahl. Beide feuern gemeinsam aus `logSearch()`.

| Wann | Bedingung |
|---|---|
| Nach jeder erfolgreichen Suche | Query ist nicht leer und Algolia hat geantwortet |

Parameter:
- `query` — der Suchbegriff (getrimmt)
- `result_count` — Anzahl gefundener Produkte

**Warum:** `result_count = 0` markiert Suchen, die ins Leere laufen — das direkteste Signal für Lücken in den Produktdaten (z. B. Begriffe, die es nur bei Diskontern ohne Vollkatalog gäbe). In BigQuery: `WHERE event_name = 'search_performed' AND result_count = 0`.

---

### `product_viewed`

| Wann | Bedingung |
|---|---|
| Beim Öffnen des Produkt-Detail-Sheets | `_showProductDetails()` in [product_card.dart](../lib/widgets/product_card.dart) |

Parameter:
- `product_id`
- `supermarket`
- `in_promotion` — `1` wenn im Angebot, sonst `0`

**Warum:** Zeigt, welche Produkte und Supermärkte tatsächlich Interesse wecken — und ob Angebote (`in_promotion = 1`) überproportional Klicks ziehen.

---

### `product_link_opened`

| Wann | Bedingung |
|---|---|
| Beim Tippen auf „Auf &lt;Supermarkt&gt; ansehen" im Detail-Sheet | Produkt hat eine `productUrl` |

Parameter:
- `product_id`
- `supermarket`

**Warum:** Stärkstes Kaufabsicht-Signal — der User verlässt die App Richtung Kauf. Zeigt außerdem, welcher Markt bei „am billigsten" gewinnt.

---

### `add_to_shopping_list`

| Wann | Bedingung |
|---|---|
| Beim ersten Hinzufügen eines Produkts zur aktiven Einkaufsliste | Nur beim ersten Mal; Mengenerhöhung (Increment) löst kein Event aus |

Parameter:
- `product_id` — Algolia-Objekt-ID des Produkts
- `supermarket` — z. B. `billa`, `spar`, `hofer`

---

### `add_to_favorites`

| Wann | Bedingung |
|---|---|
| Wenn ein Produkt zu den Favoriten hinzugefügt wird | `toggleFavorite()` wird aufgerufen und das Produkt ist noch nicht in den Favoriten |

Parameter:
- `product_id`
- `supermarket`

---

### `remove_from_favorites`

| Wann | Bedingung |
|---|---|
| Wenn ein Produkt aus den Favoriten entfernt wird | `toggleFavorite()` wird aufgerufen und das Produkt ist bereits in den Favoriten |

Parameter:
- `product_id`

---

### `price_alert_created`

| Wann | Bedingung |
|---|---|
| Nach dem Erstellen eines Preisalarms | Alarm wurde erfolgreich in Firestore gespeichert |

Parameter:
- `type` — `product` (produktgebundener Alarm) oder `keyword` (Stichwort-Alarm)

---

### `paywall_shown`

| Wann | Bedingung |
|---|---|
| Wenn der User das Free-Tier-Limit für Preisalarme erreicht hat und einen weiteren anlegen will | `_ensureCanCreateAlert()` schlägt an |

Parameter:
- `feature` — aktuell immer `alerts`

---

### `premium_purchased`

| Wann | Bedingung |
|---|---|
| Wenn der Entitlement-Stream `true` liefert und der User vorher kein Premium hatte | Einmaliger Übergang `false → true`; kein Event bei App-Restart wenn Premium bereits aktiv |

Parameter: keine

---

## Events konsumieren

### Firebase Console (Echtzeit & Aggregiert)

1. [console.firebase.google.com](https://console.firebase.google.com) → Projekt öffnen → **Analytics** → **Events**
2. Alle Custom-Events erscheinen hier, sobald sie mindestens einmal gefeuert wurden (Verarbeitung: 24–48 h Verzögerung; DebugView ist sofort)
3. **DebugView** (Echtzeit): Gerät im Debug-Modus starten (`flutter run` + `adb shell setprop debug.firebase.analytics.app <bundle-id>`), dann unter Analytics → DebugView beobachten

### Audiences & Funnels

- Unter **Analytics → Audiences** lassen sich Segmente definieren (z. B. „Hat mindestens 1 Alarm erstellt", „Hat Paywall gesehen aber nicht gekauft")
- Unter **Analytics → Funnels** kann der Conversion-Pfad `search → add_to_shopping_list → premium_purchased` analysiert werden

### BigQuery Export (rohe Event-Daten)

Für SQL-Abfragen auf Rohdaten: Firebase Console → **Projekteinstellungen → Integrationen → BigQuery verknüpfen**.  
Danach liegt jedes Event als Zeile in `analytics_<app-id>.events_YYYYMMDD`.

Beispielabfrage — wie viele User haben die Paywall gesehen und danach Premium gekauft:

```sql
WITH paywall AS (
  SELECT user_pseudo_id, event_timestamp
  FROM `<project>.analytics_<app_id>.events_*`
  WHERE event_name = 'paywall_shown'
),
purchased AS (
  SELECT user_pseudo_id, event_timestamp
  FROM `<project>.analytics_<app_id>.events_*`
  WHERE event_name = 'premium_purchased'
)
SELECT COUNT(DISTINCT p.user_pseudo_id) AS converted
FROM paywall pw
JOIN purchased p
  ON pw.user_pseudo_id = p.user_pseudo_id
 AND p.event_timestamp > pw.event_timestamp
```

### A/B Testing / Remote Config

Events können als Conversion-Ziel in Firebase Remote Config A/B-Tests verwendet werden (z. B. `premium_purchased` als Erfolgsmetrik für verschiedene Paywall-Texte).

---

## Hinweise für Entwickler

- Analytics-Calls sind immer `unawaited()` — sie blockieren die App-Logik nicht.
- In Tests wird `NoOpAnalyticsService` injiziert (`analytics: const NoOpAnalyticsService()`); Firebase Analytics wird dabei nie aufgerufen.
- `AnalyticsService` verwendet einen Lazy Getter (`FirebaseAnalytics get _analytics => FirebaseAnalytics.instance`), damit es in Test-Environments nicht crasht wenn die Instanz nicht belegt wird.
