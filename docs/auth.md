# Auth

## Ablauf

Beim ersten App-Start wird der User **silent anonymous** eingeloggt (`signInAnonymously()` in `main.dart`). Es gibt keinen Login-Screen — der User sieht nichts davon.

Will der User einen Account verknüpfen, kann er das im **Profil-Tab** tun (Google oder Apple). Dabei wird `linkWithCredential()` statt `signInWithCredential()` verwendet, damit die bestehende anonyme UID erhalten bleibt. Alle Firestore-Daten (Einkaufslisten, Alarme, Favoriten) bleiben unter derselben UID.

## Wichtig: `linkWithCredential` vs. `signInWithCredential`

- `linkWithCredential` → UID bleibt gleich, Daten bleiben erhalten ✓
- `signInWithCredential` → neue UID, anonyme Daten gehen verloren ✗

Nur wenn der User **bereits** einen echten Account hat (nicht anonym), wird `signInWithCredential` verwendet.

## Sign-out

Nach Sign-out wird automatisch wieder `signInAnonymously()` aufgerufen, damit der User immer eine UID hat und die App ohne Account voll funktioniert.

`AppState` lauscht auf `authStateChanges()` und ruft `initialize()` neu auf, wenn sich die UID ändert — so wird der neue anonyme State sauber geladen.

## Daten-Scope

Alle User-Daten liegen unter `users/{uid}/...`. Anonyme und echte Accounts funktionieren identisch — der Unterschied ist nur, ob die UID gerätegebunden ist oder nicht.

Anonyme UIDs überleben App-Restarts, aber **nicht** Reinstalls.
