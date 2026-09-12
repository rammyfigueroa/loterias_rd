# Sorteos Dominicanos - Setup de iconos de loterías

## 1. Crea esta carpeta en tu proyecto

assets/branding/lotteries/

## 2. Coloca ahí estos archivos

lottery_nacional.png
lottery_leidsa.png
lottery_real.png
lottery_loteka.png
lottery_americanas.png
lottery_new_york.png
lottery_la_primera.png
lottery_la_suerte.png
lottery_lotedom.png
lottery_anguila.png
lottery_king_lottery.png

## 3. Reemplaza este archivo

Copia `lottery_icon.dart` en:

lib/features/results/presentation/widgets/lottery_icon.dart

## 4. Actualiza pubspec.yaml

Dentro de `flutter:`, agrega:

assets:
  - assets/branding/app_icon.png
  - assets/branding/app_icon_foreground.png
  - assets/branding/logo_horizontal.png
  - assets/branding/lotteries/

Si ya tienes `assets:`, no lo dupliques. Solo agrega la línea:

  - assets/branding/lotteries/

## 5. Compila

flutter clean
flutter pub get
flutter build apk --release --dart-define=LOTTERIES_API_URL=https://api.sorteosdominicanos.workers.dev/results

adb uninstall com.sorteosdominicanos.app
adb install build/app/outputs/flutter-apk/app-release.apk

## Notas

- Si falta un icono PNG, la app no se rompe. Usa un icono FontAwesome de respaldo.
- El mapper reconoce variaciones como:
  - Quiniela Leidsa / Super Kino TV -> lottery_leidsa.png
  - Quiniela Real / Loto Real -> lottery_real.png
  - Florida / Mega Millions / Powerball -> lottery_americanas.png
  - Quemaito / LoteDom -> lottery_lotedom.png
