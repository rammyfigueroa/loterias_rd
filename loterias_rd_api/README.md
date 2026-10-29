# Loterias RD API

Backend en Cloudflare Workers para entregar resultados de loterias dominicanas en JSON.

## Endpoints

```text
GET /health
GET /results
GET /history?operatorId=...&drawId=...
GET /history/coverage?operatorId=...&drawId=...
GET /statistics/first-prize/intervals?operatorId=...&drawId=...
GET /statistics/first-prize/intervals/:days?operatorId=...&drawId=...
GET /statistics/first-prize/numbers?operatorId=...&drawId=...
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

## Historial local de Gana Más

La infraestructura historica de esta fase acepta exclusivamente:

```text
operatorId=6966a6d1ea7015c3b8a3d477
drawId=6966a6d1ea7015c3b8a3d482
```

Aplica las migraciones a D1 local:

```bash
npm run db:migrate:local
```

Inicia el Worker local con un token temporal que no debe guardarse en Git:

```bash
npx wrangler dev --local \
  --var HISTORY_BACKFILL_TOKEN:un-token-local-temporal
```

Ejecuta el backfill en lotes reanudables de hasta 50 fechas:

```bash
curl -X POST \
  'http://localhost:8787/internal/history/backfill?maxRequests=50' \
  -H 'X-Backfill-Token: un-token-local-temporal'
```

Repite la peticion mientras `hasMore` sea `true`. El limite inferior se obtiene
del `createdAt` estructurado de Gana Mas y el cursor queda almacenado en D1.

Consulta el historial paginado:

```bash
curl 'http://localhost:8787/history?operatorId=6966a6d1ea7015c3b8a3d477&drawId=6966a6d1ea7015c3b8a3d482&limit=50&order=asc'
```

No hay un Cron Trigger configurado. El handler `scheduled` esta preparado para
pruebas locales y una activacion futura expresamente autorizada.

## Estadisticas de intervalos

El motor usa solamente los resultados guardados en D1. El ranking principal
incluye intervalos con continuidad de cobertura verificada:

```bash
curl 'http://localhost:8787/statistics/first-prize/intervals?operatorId=6966a6d1ea7015c3b8a3d477&drawId=6966a6d1ea7015c3b8a3d482&coverage=verified&limit=10'
```

Los intervalos que cruzan cobertura incompleta se consultan por separado con
`coverage=incomplete`. Los valores admitidos son `verified`, `incomplete` y
`all`. Todos los endpoints son paginados y rechazan cualquier otra serie.

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
