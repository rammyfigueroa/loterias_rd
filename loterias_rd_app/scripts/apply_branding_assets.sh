#!/usr/bin/env bash
set -euo pipefail

# Applies centralized Sorteos Dominicanos branding assets when the platform
# folders exist. Safe to run multiple times.

ASSET_DIR="assets/branding"
if [ ! -d "$ASSET_DIR" ]; then
  echo "Branding assets not found at $ASSET_DIR"
  exit 1
fi

require_asset() {
  if [ ! -f "$ASSET_DIR/$1" ]; then
    echo "Missing branding asset: $ASSET_DIR/$1"
    exit 1
  fi
}

require_asset "app_icon.png"
require_asset "app_icon_foreground.png"
require_asset "sorteos_dominicanos_icon_master.png"
require_asset "app_icon_48.png"
require_asset "app_icon_72.png"
require_asset "app_icon_96.png"
require_asset "app_icon_144.png"
require_asset "app_icon_192.png"
require_asset "app_icon_512.png"

if [ -d "android/app/src/main/res" ]; then
  echo "Applying Android launcher and splash assets..."
  mkdir -p android/app/src/main/res/mipmap-mdpi \
    android/app/src/main/res/mipmap-hdpi \
    android/app/src/main/res/mipmap-xhdpi \
    android/app/src/main/res/mipmap-xxhdpi \
    android/app/src/main/res/mipmap-xxxhdpi \
    android/app/src/main/res/mipmap-anydpi-v26 \
    android/app/src/main/res/drawable \
    android/app/src/main/res/drawable-night \
    android/app/src/main/res/drawable-mdpi \
    android/app/src/main/res/drawable-hdpi \
    android/app/src/main/res/drawable-xhdpi \
    android/app/src/main/res/drawable-xxhdpi \
    android/app/src/main/res/drawable-xxxhdpi \
    android/app/src/main/res/values

  cp "$ASSET_DIR/app_icon_48.png" android/app/src/main/res/mipmap-mdpi/ic_launcher.png
  cp "$ASSET_DIR/app_icon_72.png" android/app/src/main/res/mipmap-hdpi/ic_launcher.png
  cp "$ASSET_DIR/app_icon_96.png" android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
  cp "$ASSET_DIR/app_icon_144.png" android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
  cp "$ASSET_DIR/app_icon_192.png" android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

  cat > android/app/src/main/res/values/icon_colors.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
XML

  cat > android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
XML

  cat > android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
XML

  cat > android/app/src/main/res/drawable/splash.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <solid android:color="#0B61B3" />
        </shape>
    </item>
    <item
        android:width="240dp"
        android:height="240dp"
        android:gravity="center">
        <bitmap
            android:src="@drawable/splash_logo"
            android:gravity="center"
            android:antialias="true" />
    </item>
</layer-list>
XML

  cat > android/app/src/main/res/drawable-night/splash.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <solid android:color="#062B5F" />
        </shape>
    </item>
    <item
        android:width="240dp"
        android:height="240dp"
        android:gravity="center">
        <bitmap
            android:src="@drawable/splash_logo"
            android:gravity="center"
            android:antialias="true" />
    </item>
</layer-list>
XML

  cat > android/app/src/main/res/drawable/android12splash.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:width="160dp"
        android:height="160dp"
        android:gravity="center">
        <bitmap
            android:src="@drawable/android12splash_logo"
            android:gravity="center"
            android:antialias="true" />
    </item>
</layer-list>
XML

  cp android/app/src/main/res/drawable/android12splash.xml \
    android/app/src/main/res/drawable-night/android12splash.xml

  if command -v swift >/dev/null 2>&1; then
    swift - "$ASSET_DIR/app_icon.png" "$ASSET_DIR/app_icon_foreground.png" <<'SWIFT'
import AppKit
import Foundation

func writePNG(source: String, destination: String, canvas: Int, inner: Int) throws {
    guard let image = NSImage(contentsOfFile: source) else {
        throw NSError(domain: "branding", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not load \(source)"])
    }
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: canvas,
        pixelsHigh: canvas,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: canvas, height: canvas).fill()
    let origin = CGFloat(canvas - inner) / 2.0
    image.draw(
        in: NSRect(x: origin, y: origin, width: CGFloat(inner), height: CGFloat(inner)),
        from: .zero,
        operation: .sourceOver,
        fraction: 1.0
    )
    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "branding", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not encode PNG"])
    }
    try data.write(to: URL(fileURLWithPath: destination))
}

let args = CommandLine.arguments
let icon = args[1]
let foreground = args[2]

let foregrounds: [(String, Int, Int)] = [
    ("drawable-mdpi", 108, 86),
    ("drawable-hdpi", 162, 129),
    ("drawable-xhdpi", 216, 172),
    ("drawable-xxhdpi", 324, 258),
    ("drawable-xxxhdpi", 432, 344),
]
for (folder, canvas, inner) in foregrounds {
    try writePNG(
        source: foreground,
        destination: "android/app/src/main/res/\(folder)/ic_launcher_foreground.png",
        canvas: canvas,
        inner: inner
    )
}

try writePNG(source: icon, destination: "android/app/src/main/res/drawable/splash_logo.png", canvas: 240, inner: 240)
try writePNG(source: foreground, destination: "android/app/src/main/res/drawable/android12splash_logo.png", canvas: 160, inner: 96)
SWIFT
  else
    echo "Swift not found; skipping adaptive foreground and splash PNG regeneration."
  fi

  cp android/app/src/main/res/drawable/splash_logo.png \
    android/app/src/main/res/drawable-night/splash_logo.png
  cp android/app/src/main/res/drawable/android12splash_logo.png \
    android/app/src/main/res/drawable-night/android12splash_logo.png
fi

if [ -d "web" ]; then
  echo "Applying Web icons..."
  mkdir -p web/icons
  cp "$ASSET_DIR/app_icon_48.png" web/favicon.png
  cp "$ASSET_DIR/app_icon_192.png" web/icons/Icon-192.png
  cp "$ASSET_DIR/app_icon_512.png" web/icons/Icon-512.png
  cp "$ASSET_DIR/app_icon_192.png" web/icons/Icon-maskable-192.png
  cp "$ASSET_DIR/app_icon_512.png" web/icons/Icon-maskable-512.png

  if [ -f "web/manifest.json" ]; then
    python3 - <<'PY'
import json
from pathlib import Path
p = Path('web/manifest.json')
data = json.loads(p.read_text())
data['name'] = 'Sorteos Dominicanos'
data['short_name'] = 'Sorteos'
data['description'] = 'Resultados y estadísticas de sorteos dominicanos.'
data['theme_color'] = '#003893'
data['background_color'] = '#003893'
p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n')
PY
  fi

  if [ -f "web/index.html" ]; then
    python3 - <<'PY'
from pathlib import Path
p = Path('web/index.html')
s = p.read_text()
import re
s = re.sub(r'<title>.*?</title>', '<title>Sorteos Dominicanos</title>', s, flags=re.S)
s = re.sub(
    r'<meta name="description" content=".*?">',
    '<meta name="description" content="Resultados y estadísticas de sorteos dominicanos.">',
    s,
    flags=re.S,
)
s = re.sub(
    r'<meta name="apple-mobile-web-app-title" content=".*?">',
    '<meta name="apple-mobile-web-app-title" content="Sorteos Dominicanos">',
    s,
    flags=re.S,
)
p.write_text(s)
PY
  fi
fi

echo "Branding assets applied."
