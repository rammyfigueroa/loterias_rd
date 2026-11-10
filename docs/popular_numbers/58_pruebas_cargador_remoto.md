# Pruebas del cargador remoto bloqueado

Fecha: 2026-11-09.

## Archivo

`loterias_rd_api/test/staging-fixtures-remote.test.js` valida el plan mediante
mocks y datos sintéticos. No invoca Cloudflare ni ejecuta SQL remoto.

## Casos

1. Modo predeterminado `DRY_RUN`.
2. `--apply`, `--write` y destinos personalizados rechazados.
3. Ruta ejecutable completa con inspector simulado y cero escrituras.
4. Cuenta incorrecta rechazada.
5. UUID incorrecto rechazado.
6. Nombre D1 incorrecto rechazado.
7. Worker/configuración similares a producción rechazados.
8. Migración pendiente, faltante o adicional bloqueada.
9. Esquema inesperado bloqueado.
10. Identidades, backfill o integridad inesperados bloqueados.
11. Colisión de resultado bloqueada sin considerarla idempotente.
12. Carga parcial bloqueada.
13. Fixture completo reconocido como `ALREADY_APPLIED`.
14. Fixture de 5,000 eventos excluido.
15. Comandos limitados a consultas `SELECT`/`PRAGMA`.

## Validaciones previstas

```sh
node --check scripts/load-staging-fixtures-remote.js
node --check test/staging-fixtures-remote.test.js
node --test test/staging-fixtures-remote.test.js
node --test test/staging-fixtures.test.js test/staging-fixtures-remote.test.js
npm test
git diff --check
```

La advertencia `punycode` procede de Wrangler/Node y ya existía antes de esta
fase. No afecta el resultado funcional.

Resultados finales:

- pruebas específicas del cargador remoto: 11/11;
- fixtures local y remoto combinados: 22/22;
- suite completa del backend: 106/106;
- validación de sintaxis Node: aprobada;
- `git diff --check`: aprobado;
- fallos pendientes: 0.

## Pruebas remotas

No se ejecutó el comando real de dry run contra Cloudflare durante 8.5B-7A.
Esta decisión mantiene toda la validación en mocks y D1 locales efímeras, tal
como exige la fase. Las consultas remotas de solo lectura quedan preparadas
para una ejecución expresamente autorizada posterior.
