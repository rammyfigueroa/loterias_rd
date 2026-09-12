#!/usr/bin/env bash
set -euo pipefail

./scripts/build_web_release.sh
./scripts/build_android_release.sh
