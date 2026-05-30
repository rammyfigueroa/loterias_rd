#!/usr/bin/env bash
set -euo pipefail

flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
