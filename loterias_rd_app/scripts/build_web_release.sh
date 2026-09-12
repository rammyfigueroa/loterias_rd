#!/usr/bin/env bash
set -euo pipefail

API_URL="${LOTTERIES_API_URL:-https://api.sorteosdominicanos.workers.dev/results}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter no esta instalado o no esta en el PATH."
  echo "Instala Flutter o abre una terminal donde el comando 'flutter' funcione."
  exit 1
fi

if [ ! -d "web" ]; then
  echo "No existe carpeta web. Creando plataforma web..."
  flutter create --platforms=web .
fi

echo "Limpiando proyecto..."
flutter clean

echo "Instalando dependencias..."
flutter pub get

if [ -x "./scripts/apply_branding_assets.sh" ]; then
  ./scripts/apply_branding_assets.sh
fi

echo "Generando build Web release con API: $API_URL"
flutter build web --release --dart-define=LOTTERIES_API_URL="$API_URL"

echo "Build Web listo en: build/web"
echo "Puedes subir el contenido de build/web a Cloudflare Pages, Netlify, Vercel o tu hosting."
