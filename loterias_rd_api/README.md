# Loterias RD API

Backend en Cloudflare Workers para entregar resultados de loterias dominicanas en JSON.

## Endpoints

```text
GET /health
GET /results
```

Respuesta de `/results`:

```json
{
  "source": "https://loteriasdominicanas.com/",
  "updatedAt": "2026-05-30T00:00:00.000Z",
  "count": 1,
  "results": [
    {
      "lotteryName": "Nacional",
      "drawName": "Juega + Pega +",
      "drawDate": "29-05",
      "numbers": ["13", "16", "19", "26", "25"],
      "prize": null,
      "isVerified": true
    }
  ]
}
```

## Ejecutar local

```bash
cd loterias_rd_api
npm install
npm test
npm run dev
```

Prueba local:

```bash
curl http://localhost:8787/health
curl http://localhost:8787/results
```

## Publicar en Cloudflare

Instala Wrangler localmente e inicia sesion:

```bash
cd loterias_rd_api
npm install
npx wrangler login
```

Publica:

```bash
npm run deploy
```

Cloudflare devolvera una URL similar a:

```text
https://loterias-rd-api.tu-usuario.workers.dev
```

Cuando tengas esa URL, colocala en la app Flutter en:

```dart
lib/core/constants/app_constants.dart
```

```dart
static const apiResultsUrl = 'https://tu-worker.workers.dev/results';
```

## Notas de produccion

- El cache por defecto es de 180 segundos.
- La API permite CORS con `*` para facilitar pruebas web.
- Antes de publicar la app en tiendas, agrega un aviso legal indicando que los resultados son informativos y deben verificarse con la entidad oficial correspondiente.
