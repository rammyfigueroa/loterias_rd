# Instrucciones locales de release

## 1. Abrir el proyecto correcto

Abrir esta carpeta en Android Studio o VS Code:

`/Users/rammyfigueroa/AndroidStudioProjects/sorteosdominicanos_project/sorteosdominicanos_app`

## 2. Confirmar credenciales de firma

Crear el archivo local:

```bash
cp android/key.properties.example android/key.properties
```

Editar `android/key.properties` con los valores reales del upload key de Google Play.

Confirmar que exista el keystore:

```bash
ls -l android/app/upload-keystore.jks
```

## 3. Validar backend

```bash
./test_backend.sh
```

## 4. Validar y generar release

```bash
./validate_release.sh
```

Este script genera el AAB firmado en:

`build/app/outputs/bundle/release/sorteosdominicanos.aab`

## 5. Comando manual equivalente

```bash
flutter clean
flutter pub get
flutter analyze
flutter build appbundle --release --dart-define=LOTTERIES_API_URL=https://api.sorteosdominicanos.workers.dev/results
```

## 6. Archivo para Play Console

Subir a Internal Testing:

`build/app/outputs/bundle/release/sorteosdominicanos.aab`
