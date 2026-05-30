# Loterias RD

Proyecto completo con:

- `loterias_rd_app`: app Flutter para Android, iOS y web.
- `loterias_rd_api`: backend Cloudflare Worker que entrega resultados en JSON.

La app incluye lista de resultados, busqueda, filtros, favoritos locales, pantalla de detalle y compartir resultados.

## Orden recomendado

1. Publica el backend:

```bash
cd loterias_rd_api
npm install
npm test
npx wrangler login
npm run deploy
```

2. Copia la URL publicada por Cloudflare, por ejemplo:

```text
https://loterias-rd-api.tu-usuario.workers.dev
```

3. Ejecuta la app con esa API:

```bash
cd ../loterias_rd_app
flutter pub get
flutter run -d chrome --dart-define=LOTTERIES_API_URL=https://loterias-rd-api.tu-usuario.workers.dev/results
```

Para la API ya publicada en este proyecto tambien puedes usar:

```bash
./run_web.sh
```

Y para compilar web:

```bash
./build_web.sh
```

Para preparar icono/splash Android y generar un APK de prueba:

```bash
./fix_android_v2_embedding.sh
./setup_android_branding.sh
./build_android_apk.sh
```

Usa `fix_android_v2_embedding.sh` solo si tu carpeta `android/` local fue creada con el Android v1 embedding antiguo o si Flutter muestra ese error durante el build.

Para generar el App Bundle de Google Play:

```bash
./build_android_appbundle.sh
```

Para Android o iOS usa el mismo `--dart-define`.

## Fuentes oficiales usadas

Cloudflare recomienda instalar Wrangler localmente en cada proyecto con `npm i -D wrangler@latest` y usar comandos como `npx wrangler login` o scripts de npm para desplegar. Consulta la guia oficial si cambia algun paso: https://developers.cloudflare.com/workers/wrangler/install-and-update/
