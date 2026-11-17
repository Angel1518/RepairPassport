# RepairPassport

> **«La historia de tus objetos, no otra lista de compras»**

![Android](https://img.shields.io/badge/Android-Offline--First-15803D)
![Flutter](https://img.shields.io/badge/Flutter-Material%203-blue)
![Zero Telemetry](https://img.shields.io/badge/Telemetr%C3%ADa-0%25-success)

**RepairPassport** es una aplicación Android de código abierto para documentar la vida útil, reparaciones, piezas sustituidas y garantías de tus dispositivos, bicicletas, electrodomésticos o herramientas, y entregar un **pasaporte verificable** al vender o ceder un objeto de segunda mano.

---

## Características principales

- **100 % Offline-First**: todos los objetos, reparaciones, piezas y exportaciones se procesan y guardan localmente en SQLite.
- **Línea temporal técnica**: registra fecha, síntoma, solución aplicada, coste, técnico o autorreparación (`Propio / DIY`) y piezas con referencia.
- **Pasaporte QR offline**: genera al instante un código QR con el resumen JSON compacto de las reparaciones confirmadas, escaneable sin conexión.
- **Exportación PDF, JSON y ZIP**: genera una ficha imprimible en PDF o un paquete ZIP con `passport.json`, `summary.txt` y `manifest.sha256`.
- **IA opcional BYOK (gratuita)**: desactivada por defecto. Permite estructurar notas técnicas informales tras pasar por el diálogo de revisión y redacción previa.

---

## Privacidad y política de IA gratuita

- Sin cuentas, sin anuncios, sin analítica ni rastreadores.
- Las claves API opcionales se almacenan cifradas en **Android Keystore** (`flutter_secure_storage`) y nunca se exportan ni registran.
- Política de **coste cero estricto**: solo permite `openrouter/free` / modelos `$0` verificados, nivel gratuito de Google AI Studio o servidores locales compatibles (Ollama / LM Studio).

---

## Instalación y compilación local

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

El APK generado se encuentra en `build/app/outputs/flutter-apk/app-release.apk`.

---

## Límites conocidos y contribuciones

- El código QR compacto incluye las 3 reparaciones confirmadas más recientes para mantener una densidad cómoda de escaneo; el historial completo se exporta en PDF/ZIP.
- Consulta [DEPENDENCIES.md](DEPENDENCIES.md) y [CONTRIBUTING.md](CONTRIBUTING.md) para más detalles.
