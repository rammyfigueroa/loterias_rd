#!/usr/bin/env bash
set -euo pipefail

API_URL="${LOTTERIES_API_URL:-https://api.sorteosdominicanos.workers.dev/results}"
BUILD_AAB="${BUILD_AAB:-true}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter no esta instalado o no esta en el PATH."
  echo "Instala Flutter o abre una terminal donde el comando 'flutter' funcione."
  exit 1
fi

if [ ! -d "android" ]; then
  echo "No existe carpeta android. Creando plataforma Android..."
  flutter create --platforms=android .
fi

echo "Limpiando proyecto..."
flutter clean

echo "Instalando dependencias..."
flutter pub get

if [ -x "./scripts/apply_branding_assets.sh" ]; then
  ./scripts/apply_branding_assets.sh
fi

echo "Generando APK release con API: $API_URL"
flutter build apk --release --dart-define=LOTTERIES_API_URL="$API_URL"

echo "APK listo en: build/app/outputs/flutter-apk/app-release.apk"

if [ "$BUILD_AAB" = "true" ]; then
  echo "Generando AAB release para Play Store..."
  flutter build appbundle --release --dart-define=LOTTERIES_API_URL="$API_URL"
  echo "AAB listo en: build/app/outputs/bundle/release/app-release.aab"
fi
