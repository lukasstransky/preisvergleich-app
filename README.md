# Preisvergleich App

Flutter App zum Vergleich von Lebensmittelpreisen bei österreichischen Supermärkten (Spar, Billa, Hofer, Penny, Lidl, Mpreis).

## iPhone Installation

### Einmalig per Kabel

```bash
flutter run --release
```

Mit verbundenem iPhone ausführen. Beim ersten Mal auf dem iPhone unter **Einstellungen → Allgemein → VPN & Geräteverwaltung** dem Entwickler-Zertifikat vertrauen ("Trust").

Die App bleibt danach auf dem iPhone installiert und funktioniert ohne Kabel.

### Updates ohne Kabel (WLAN)

1. Einmalig per Kabel verbinden und Xcode öffnen
2. **Window → Devices and Simulators** → iPhone auswählen → **"Connect via network"** aktivieren
3. Ab dann reicht es, wenn iPhone und Mac im selben WLAN sind — `flutter run` funktioniert ohne Kabel

### Hinweis

Mit einem kostenlosen Apple Developer Account läuft die App nur **7 Tage**, danach muss neu installiert werden. Mit dem bezahlten Account ($99/Jahr) läuft sie **1 Jahr**.
