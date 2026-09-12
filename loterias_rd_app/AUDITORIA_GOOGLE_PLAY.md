# Auditoria Google Play - Sorteos Dominicanos

## Segunda fase de validacion

Fecha local de validacion: 2026-09-10

Esta auditoria se enfoca en preparar la app para pruebas internas en Google Play. No garantiza aprobacion por Google Play; solo documenta el estado tecnico y los riesgos conocidos antes de subir el bundle.

## Estado tecnico actual

- Stack detectado: Flutter con proyecto Android nativo en `android/`.
- Package/applicationId: `com.sorteosdominicanos.app`.
- Version actual: `1.0.3+7`.
- Android SDK: `compileSdk = 36`, `targetSdk = 36`.
- Formato recomendado para Play Console: Android App Bundle (`.aab`).
- API usada por la app: `https://api.sorteosdominicanos.workers.dev/results`.
- Permisos Android detectados: solo `android.permission.INTERNET`.
- No se detectaron compras, apuestas, login, pagos, anuncios ni servicios en background en el manifiesto principal.

## Backend

El backend publico respondio correctamente durante esta validacion:

- `GET /health`: HTTP 200, JSON valido, CORS habilitado.
- `GET /results`: HTTP 200, JSON valido, CORS habilitado.
- Respuesta observada: 85 resultados.
- Fuente reportada: `https://api.conectate.com.do/conectate`.
- Wrangler `deploy --dry-run`: correcto, sin publicar cambios.

Riesgo: el Worker depende de fuentes externas. Si esas fuentes devuelven 403, cambian HTML/API o tardan demasiado, la app puede mostrar el estado de error de red aunque el codigo de la app este bien.

## Firma release

El proyecto espera credenciales locales en `android/key.properties`.

Archivos sensibles que no deben subirse:

- `android/key.properties`
- `android/app/upload-keystore.jks`
- cualquier `*.jks` o `*.keystore`

Se agrego `android/key.properties.example` como plantilla segura. El build release ahora falla con un mensaje claro si faltan credenciales.

## Compatibilidad Flutter, Gradle, AGP y JDK

Estado observado localmente:

- Flutter: 3.44.0 stable.
- Gradle wrapper: 9.1.0.
- Android Gradle Plugin: 9.0.1.
- Kotlin Android plugin: 2.3.20.
- JDK usado por Gradle: 25.0.2.

Gradle 9.1.0 inicia correctamente con JDK 25.0.2, aunque muestra warnings de acceso nativo restringido. Esos warnings no son bloqueo de Play Store, pero para builds locales reproducibles se recomienda usar JDK 17 o 21 si Android Studio/Flutter lo tienen configurado.

## Validaciones agregadas

- `test_backend.sh`: valida `/health` y `/results`, confirma JSON valido, campos minimos y cantidad de resultados.
- `validate_release.sh`: valida backend, credenciales de firma, `flutter clean`, `flutter pub get`, `flutter analyze`, pruebas Flutter si existen, debug APK y AAB release firmado.

Resultado local de `validate_release.sh`:

- Debug APK generado: `build/app/outputs/flutter-apk/app-debug.apk`.
- Release AAB firmado generado: `build/app/outputs/bundle/release/sorteosdominicanos.aab`.
- SHA-256 del AAB: `87c93ac2ff413b106c076372c92d666d73fad523648ced06bf5b46ae4663b03e`.

## Checklist antes de Internal Testing

- Ejecutar `./test_backend.sh`.
- Ejecutar `./validate_release.sh`.
- Confirmar que el AAB generado esta en `build/app/outputs/bundle/release/sorteosdominicanos.aab`.
- Probar la app instalada en un Android real antes de subir a Play Console.
- Confirmar en Play Console que el nombre, descripcion, politica de privacidad y declaracion de loterias describen la app como informativa.

## Fuentes oficiales usadas

- Google Play target API level requirements: https://support.google.com/googleplay/android-developer/answer/11926878
- Google Play app bundles: https://support.google.com/googleplay/android-developer/answer/9859152
