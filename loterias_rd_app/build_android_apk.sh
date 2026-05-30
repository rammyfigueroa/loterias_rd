#!/usr/bin/env bash
set -euo pipefail

flutter pub get
flutter build apk --release \
  --dart-define=LOTTERIES_API_URL=https://loteriasrd.workers.dev/results

echo "APK generado en: build/app/outputs/flutter-apk/app-release.apk"
