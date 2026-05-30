# Loterias RD App

App Flutter para consultar resultados de las loterias de Republica Dominicana con una interfaz moderna en azul, blanco y rojo.

## Fuente de datos

Se reviso si existia una API publica gratuita y documentada para resultados de loterias dominicanas. No se encontro una opcion confiable y abierta. Por eso el MVP puede usar como fuente inicial el HTML publico de `https://loteriasdominicanas.com/` y lo procesa en `LotteryResultsParser`.

La arquitectura deja la fuente separada en `LotteryResultsRemoteSource`. Si configuras `LOTTERIES_API_URL`, la app consume primero tu backend Cloudflare Worker. Si no configuras esa variable, intenta leer desde la web fuente directamente.

## Funciones del MVP

- Lista de resultados por loteria y sorteo.
- Nombres claros: Nacional, Leidsa, Loteria Real, Loteka, La Primera, La Suerte, LoteDom, Anguila, King Lottery y Americanas.
- Numeros ganadores en bolas visuales.
- Busqueda por loteria, sorteo o numero.
- Filtro horizontal por loteria.
- Favoritos guardados localmente en el dispositivo.
- Pantalla de detalle por sorteo.
- Compartir resultados con el menu nativo del sistema.
- Pull to refresh y boton de actualizar.
- Estado de carga.
- Datos de muestra si la fuente web falla o bloquea la solicitud.

## Estructura

```text
lib/
  app/
    app.dart
    theme/app_theme.dart
  core/constants/app_constants.dart
  features/results/
    data/
      lottery_results_parser.dart
      lottery_results_remote_source.dart
      lottery_results_repository.dart
      sample_results.dart
    domain/lottery_result.dart
    presentation/
      results_page.dart
      widgets/
```

## Como ejecutarla

1. Instala Flutter desde la documentacion oficial: https://docs.flutter.dev/get-started/install
2. Entra a la carpeta del proyecto:

```bash
cd loterias_rd_app
```

3. Descarga dependencias:

```bash
flutter pub get
```

4. Si tu Flutter necesita carpetas nativas de Android/iOS, generarlas dentro de esta carpeta:

```bash
flutter create .
```

5. Ejecuta en Android, iOS o web:

```bash
flutter run
```

Con la API de Cloudflare Workers publicada:

```bash
flutter run -d chrome --dart-define=LOTTERIES_API_URL=https://tu-worker.workers.dev/results
```

Para Android/iOS usa el mismo `--dart-define`.

Este proyecto ya incluye scripts para la API publicada en Cloudflare:

```bash
./run_web.sh
```

Para generar el build web:

```bash
./build_web.sh
```

Ambos usan:

```text
https://loteriasrd.workers.dev/results
```

## Android: icono, splash y builds

Si el build muestra este error:

```text
Build failed due to use of deleted Android v1 embedding.
```

Regenera la carpeta nativa Android con el embedding actual:

```bash
./fix_android_v2_embedding.sh
```

El script respalda la carpeta `android` anterior antes de crear una nueva.

Antes del primer build Android, genera el icono y splash nativos:

```bash
./setup_android_branding.sh
```

APK de prueba para instalar en telefono:

```bash
./build_android_apk.sh
```

Archivo generado:

```text
build/app/outputs/flutter-apk/app-release.apk
```

App Bundle para Google Play:

```bash
./build_android_appbundle.sh
```

Archivo generado:

```text
build/app/outputs/bundle/release/app-release.aab
```

Los scripts Android usan la API publicada:

```text
https://loteriasrd.workers.dev/results
```

## Pruebas y revision

```bash
flutter analyze
flutter test
```

Si agregaste esta version sobre una carpeta anterior, actualiza dependencias primero:

```bash
flutter pub get
```

## Siguiente fase recomendada

- Crear un backend ligero en Firebase Functions, Supabase Edge Functions o Cloudflare Workers para hacer el scraping del lado servidor. Esto evita bloqueos CORS en web y permite cachear resultados.
- Agregar notificaciones push para resultados nuevos.
- Crear politica de privacidad antes de publicar, aclarando que la app es informativa y que los premios deben verificarse con la loteria oficial.
