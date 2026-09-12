# Auditoria final para acceso a produccion

## Estado

Estado general: **lista con pendientes no bloqueantes**.

La app tiene un Android App Bundle de release generado correctamente y el backend principal respondio correctamente durante la auditoria. No se encontraron permisos sensibles, SDKs de anuncios, compras, apuestas, pagos, depositos, retiros, cuentas obligatorias ni WebViews para transacciones.

La solicitud de acceso a produccion en Google Play aun depende de pasos manuales en Play Console, especialmente cumplir la prueba cerrada requerida por Google Play, completar las declaraciones de privacidad/Data Safety/contenido y revisar la ficha publica antes de enviar.

## Versión auditada

- App Flutter/Android: **Sorteos Dominicanos**.
- `versionName`: **1.0.3**.
- `versionCode`: **7**.
- `applicationId`: **com.sorteosdominicanos.app**.
- `namespace`: **com.sorteosdominicanos.app**.
- `minSdkVersion`: **24** segun manifest fusionado de release.
- `targetSdkVersion`: **36**.
- `compileSdk`: **36**.

## Build

Resultado del build de release: **correcto**.

- Comando ejecutado:
  - `flutter build appbundle --release --dart-define=LOTTERIES_API_URL=https://api.sorteosdominicanos.workers.dev/results`
- AAB generado:
  - `build/app/outputs/bundle/release/app-release.aab`
- SHA-256:
  - `ba0f0e5aa350f5a8a810fe7b447f82608f62954ddfd214e26d905cab9e5ced2e`
- Tamano:
  - `61121217 bytes`

Validaciones ejecutadas:

- `flutter clean`: correcto.
- `flutter pub get`: correcto.
- `flutter analyze`: falla en modo estricto por warnings/infos existentes, no por errores de compilacion.
- `flutter analyze --no-fatal-infos --no-fatal-warnings`: correcto.
- `flutter test`: no pudo ejecutarse por un artefacto faltante del SDK local de Flutter: `flutter_tester` en `bin/cache/artifacts/engine/darwin-x64/flutter_tester`.
- `./test_backend.sh`: correcto.
- `./validate_release.sh`: falla por el mismo problema local de `flutter test`; backend, firma, pub get y analyze no fatal pasaron antes de ese punto.

Notas:

- El warning de `shared_preferences_android` sobre Kotlin Gradle Plugin es un riesgo futuro de compatibilidad, no bloqueo actual del AAB.
- La firma de release esta configurada para fallar si faltan valores de `android/key.properties`; no hay fallback a firma debug para release.
- `android/key.properties` y keystores estan excluidos por `.gitignore`.

## Backend

Endpoint auditado:

- `https://api.sorteosdominicanos.workers.dev/results`

Resultado:

- `/health`: HTTP 200 con JSON valido.
- `/results`: HTTP 200 con JSON valido.
- Resultados recibidos durante la auditoria: **85**.
- Fuente reportada por el backend: `https://api.conectate.com.do/conectate`.
- Primer resultado observado: `King Lottery - Philipsburg Noche - 2026-09-11`.

Uso en la app:

- La fuente remota por defecto apunta a `https://api.sorteosdominicanos.workers.dev/results`.
- El build de release se genero con `LOTTERIES_API_URL=https://api.sorteosdominicanos.workers.dev/results`.
- La pantalla de resultados muestra error y boton de reintento si la API falla.
- La app no usa actualmente el fallback de `sample_data.dart`; ese archivo existe, pero el repositorio de resultados llama solo a la fuente remota.

Riesgo no bloqueante:

- El backend depende de una fuente externa. Si `api.conectate.com.do` cambia estructura, disponibilidad o politica de acceso, la app podria mostrar error aunque el AAB sea correcto.

## Permisos

Permisos observados en el manifest fusionado de release:

- `android.permission.INTERNET`
- `com.sorteosdominicanos.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`

No se observaron permisos de:

- Ubicacion.
- Camara.
- Microfono.
- Contactos.
- SMS.
- Registro de llamadas.
- Almacenamiento externo amplio.
- Notificaciones push.
- Identificador de anuncios `AD_ID`.

Componentes relevantes:

- `ShareFileProvider` de `share_plus`, no exportado.
- Receiver de `share_plus`, no exportado.
- AndroidX Startup/Profile Installer generados por dependencias AndroidX.

Conclusion: permisos coherentes con una app informativa que consume internet y permite compartir resultados.

## Privacidad

La app no muestra login, registro, pagos, apuestas, compras, analiticas, SDKs de anuncios ni recoleccion directa de datos personales desde el codigo revisado.

Datos locales:

- Favoritos/preferencias se guardan localmente mediante `shared_preferences`.

Puntos que deben revisarse antes de enviar:

- La politica de privacidad debe incluir un correo de contacto real, no placeholder.
- Debe aclarar que el backend esta alojado en Cloudflare Workers o infraestructura equivalente si esa es la configuracion final.
- Debe aclarar si Cloudflare, logs de servidor o fuentes externas reciben IP, user-agent, fecha/hora u otros datos tecnicos de solicitud.
- Debe aclarar que la funcion de compartir entrega el texto al sistema Android y a la app elegida por el usuario.

## Data Safety

Declaracion recomendada segun el codigo auditado:

- Ads: **No**.
- Compra dentro de la app: **No**.
- Login/cuentas: **No**.
- Datos personales recolectados por la app: **No observado en codigo**.
- Ubicacion: **No**.
- Contactos: **No**.
- Fotos/videos/audio: **No**.
- Archivos del usuario: **No**, salvo el proveedor interno usado por `share_plus` para compartir contenido generado por la app.
- Diagnosticos/identificadores: **No observado via SDKs**, pero debe confirmarse configuracion de logs en Cloudflare y servicios externos.

Pendiente manual:

- Completar Data Safety en Play Console segun la configuracion real de infraestructura, especialmente logs tecnicos del backend.

## Ads

No se encontraron dependencias ni permisos de anuncios:

- No `google_mobile_ads`.
- No AdMob App ID.
- No `AD_ID`.
- No SDKs comunes de monetizacion por anuncios.

Declaracion recomendada en Play Console: **la app no contiene anuncios**, si no se agregan SDKs o pantallas publicitarias antes de publicar.

## App Access

No se encontro acceso restringido por:

- Login.
- Registro.
- Suscripcion.
- Codigo privado.
- Rol de usuario.
- Pago.
- Region bloqueada desde app.

Declaracion recomendada en Play Console: **todas las funcionalidades son accesibles sin credenciales**, salvo que el backend externo falle temporalmente.

## Lotería / apuestas

La app trata resultados de loterias como contenido informativo.

No se encontro funcionalidad de:

- Apostar.
- Comprar boletos.
- Pagar.
- Depositar o retirar dinero.
- Wallet.
- Premios pagados por la app.
- Casino.
- Simulador de apuestas.
- Afiliados de apuestas.
- WebView hacia paginas de juego o pago.

Riesgos de revision:

- El tema de loteria puede activar preguntas de juego/apuestas en Play Console aunque la app sea informativa.
- La app debe declarar claramente que no permite apostar ni comprar boletos.
- Debe evitar afirmar que es oficial, autorizada o afiliada a una loteria si no existe permiso formal.

## Target Audience

Recomendacion:

- No marcar la app como dirigida a ninos.
- Usar audiencia adulta/general adecuada para una app informativa de resultados de loterias.

Motivo:

- Aunque no hay apuestas ni dinero real dentro de la app, el tema principal es loteria.

## Content Rating

Recomendacion para el cuestionario:

- Contestar que la app no permite apuestas con dinero real.
- Contestar que no permite compra de boletos, pagos, depositos ni retiros.
- Indicar con precision que muestra informacion de resultados de loterias.
- No declarar juego simulado si no existe esa funcion.

La clasificacion final dependera del cuestionario de Google Play/IARC.

## Store Listing

Material encontrado:

- `GOOGLE_PLAY_LISTING_DRAFT.md`
- `PLAY_CONSOLE_DATA_SAFETY.md`
- `PLAY_CONSOLE_LOTTERY_DECLARATION.md`
- `release/PLAY_STORE_CHECKLIST.md`

Estado:

- La ficha propuesta describe la app como informativa.
- Declara que no permite apostar, pagar, comprar boletos ni reclamar premios.
- No se encontro referencia activa al simulador educativo en codigo ni UI.

Pendientes:

- Revisar screenshots finales en dispositivos reales.
- Confirmar categoria de app en Play Console.
- Confirmar que el icono 512x512 de alta resolucion sea el definitivo.
- Revisar que textos no sugieran afiliacion oficial.

## Testing

Validado:

- Backend responde correctamente.
- AAB release se genera correctamente.
- Manifest release auditado.
- Permisos revisados.
- Dependencias revisadas para anuncios, pagos, WebViews, analiticas y permisos sensibles.
- Build usa endpoint de produccion esperado.

No validado completamente:

- `flutter test` por problema del SDK local de Flutter con `flutter_tester`.
- Prueba manual completa en dispositivo fisico desde el AAB subido a Play Console/internal testing.
- Flujo completo de closed testing requerido por Google Play.

## Riesgos

Riesgos no bloqueantes:

- `flutter analyze` estricto reporta warnings/infos de deuda tecnica.
- `flutter test` no corre por artefacto faltante del SDK local.
- Dependencia `shared_preferences_android` muestra warning futuro de Kotlin Gradle Plugin.
- Existe `sample_data.dart` con datos ficticios y comentario de fallback, aunque actualmente no esta usado por el repositorio.
- Hay archivos duplicados o historicos de pantallas `*2.dart` que conviene limpiar despues.
- El backend depende de una fuente externa.
- Los logos/nombres de loterias pueden requerir revision de derechos de uso y lenguaje de marca.
- La politica de privacidad debe completar contacto real y tratamiento de logs tecnicos.

Riesgos bloqueantes encontrados:

- Ninguno tecnico para generar el AAB.
- Ninguno de permisos sensibles o funcionalidades prohibidas observado en el codigo auditado.

## Pendientes en Play Console

- Completar closed testing antes de solicitar produccion, si la cuenta esta sujeta al requisito de Google Play.
- Confirmar que hubo al menos 12 testers opt-in durante 14 dias continuos antes de solicitar acceso a produccion, si aplica.
- Subir el AAB de release.
- Completar Data Safety segun infraestructura real.
- Completar privacy policy URL publica.
- Completar ads declaration como "No ads", si no se agregan anuncios.
- Completar App Access como sin credenciales, si no se agrega login.
- Completar Content Rating/IARC con respuestas exactas.
- Completar Target Audience sin marcar ninos como audiencia objetivo.
- Revisar Store Listing, screenshots, icono 512x512, descripcion corta y descripcion larga.
- Confirmar categoria y datos de contacto de soporte.

## Pendientes manuales

- Revisar la app instalada desde un canal de prueba de Play Console en al menos un dispositivo Android real.
- Verificar visualmente icono, splash, pantalla principal, detalle, favoritos y compartir.
- Verificar que el endpoint de produccion sigue respondiendo antes de enviar revision.
- Publicar/actualizar politica de privacidad con correo real y descripcion de logs tecnicos.
- Guardar de forma segura keystore, alias, passwords y evidencia de version enviada.
- Confirmar que no se agregaron anuncios, analiticas, login, pagos o WebViews despues de esta auditoria.

## Decisión final

**DECISIÓN: LISTA CON PENDIENTES NO BLOQUEANTES**

La app esta tecnicamente preparada para generar y subir un AAB de release a Play Console, pero la solicitud final de acceso a produccion todavia depende de pendientes manuales de Play Console y de completar/revisar documentacion de privacidad, Data Safety, content rating, closed testing y store listing.
