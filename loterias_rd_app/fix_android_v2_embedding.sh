#!/usr/bin/env bash
set -euo pipefail

backup_dir="android_v1_backup_$(date +%Y%m%d_%H%M%S)"

if [ -d "android" ]; then
  echo "Respaldando carpeta android actual en: ${backup_dir}"
  mv android "${backup_dir}"
fi

flutter create --platforms=android --org com.rammyfigueroa .
flutter pub get

echo "Android fue regenerado con el embedding actual de Flutter."
echo "Ahora ejecuta: ./setup_android_branding.sh && ./build_android_apk.sh"
