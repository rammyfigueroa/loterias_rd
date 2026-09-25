# Build Android Release - Sorteos Dominicanos

## Comando recomendado

```bash
./scripts/build_android_release.sh
```

O manualmente:

```bash
flutter clean
flutter pub get
flutter build apk --release --dart-define=LOTTERIES_API_URL=https://api.sorteosdominicanos.workers.dev/results
flutter build appbundle --release --dart-define=LOTTERIES_API_URL=https://api.sorteosdominicanos.workers.dev/results
```

## Archivos generados

APK para instalar y probar:

```bash
build/app/outputs/flutter-apk/app-release.apk
```

AAB para Play Store:

```bash
build/app/outputs/bundle/release/app-release.aab
```

## Antes de publicar en Play Store

Revisa estos puntos:

1. Cambiar el package/applicationId si todavia aparece como `com.example...`.
2. Configurar icono final.
3. Configurar splash screen.
4. Probar en Android real.
5. Revisar textos legales: app informativa/educativa, no apuestas.
6. Crear capturas para Play Store.
7. Firmar el AAB con una keystore de produccion.

## Nota sobre notificaciones

La version actual esta limpia para Web y Android sin `flutter_local_notifications`. Las notificaciones se pueden agregar en una fase posterior, solo cuando Android este estable.
