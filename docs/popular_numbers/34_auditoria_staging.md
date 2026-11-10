# Auditoría de staging aislado

Fecha: 2026-11-09.

## Alcance

Esta auditoría es preparatoria. No crea recursos, no aplica migraciones, no
despliega Workers y no modifica variables, rutas, DNS ni bases remotas.

## Estado Git

- Rama: `production-access-ready`.
- HEAD: `cad6622 feat: preserve dreams and numbers module behind disabled feature flag`.
- La rama sigue a `origin/production-access-ready`.
- Existe una modificación rastreada previa en
  `loterias_rd_api/src/statistics/routes.js`.
- Existen archivos sin seguimiento de fases anteriores, incluidos el motor,
  servicio y pruebas de transiciones, documentación, `.idea/`, `.DS_Store` e
  `loterias_rd_app/ios/`.
- Ninguno de esos cambios fue alterado durante esta fase.

## Configuración declarada

### Configuración principal

`loterias_rd_api/wrangler.toml` declara:

- Worker: `loterias-rd-api`.
- Binding: `HISTORY_DB`.
- D1: `gana-mas-history-dev`.
- `database_id`: UUID cero de marcador.
- Variables no secretas: `SOURCE_URL` y `CACHE_SECONDS`.
- Sin rutas, dominios ni triggers declarados.

### Configuración de staging

`loterias_rd_api/wrangler.staging.toml` declara:

- Worker: `sorteosdominicanos-history-staging`.
- D1: `sorteosdominicanos-history-staging-db`.
- Binding: `HISTORY_DB`.
- `database_id`: UUID cero de marcador.
- `ENVIRONMENT = "staging"`.
- `workers_dev = true` y `preview_urls = false`.
- Sin rutas ni triggers declarados.
- Compatibilidad `2026-10-01`, distinta de la principal (`2025-01-01`).

Los nombres distintos evitarían que un despliegue que use explícitamente
`--config wrangler.staging.toml` reemplace el script declarado por
`wrangler.toml`. Esto no basta para confirmar aislamiento: falta un D1 real y
debe comprobarse su ID antes de cualquier despliegue.

## Recursos remotos verificados

Las consultas remotas de solo lectura se ejecutaron con Wrangler 4.155.0 y la
sesión OAuth ya configurada, sin mostrar ni copiar credenciales.

- `sorteosdominicanos-history-staging`: no existe en la cuenta consultada
  (Cloudflare API, código 10007).
- `loterias-rd-api`: no existe en la cuenta consultada (código 10007).
- D1 visibles en la cuenta consultada: ninguno (`[]`).

Esta verificación solo describe la cuenta activa de Wrangler. No demuestra que
el API público no exista en otra cuenta o bajo otra configuración.

## D1 y migraciones

Existen dos migraciones locales:

1. `0001_gana_mas_history.sql`: esquema, índices y serie Gana Más.
2. `0002_national_history.sql`: serie Lotería Nacional.

El esquema impone unicidad de identidad del proveedor y de sorteo/fecha,
mantiene cobertura, revisiones y estado de backfill. No se ejecutó ninguna
migración remota. Ambos archivos Wrangler usan un UUID cero, por lo que no hay
un binding remoto utilizable ni evidencia de que apunten a bases diferentes.

## Dependencias y exposición

- El endpoint de transiciones depende únicamente de `HISTORY_DB` y de las dos
  series autorizadas por IDs exactos.
- El Worker incluye `/results`, rutas históricas, estadísticas y un handler
  `scheduled`; no hay cron configurado.
- `/internal/history/backfill` exige `HISTORY_BACKFILL_TOKEN`.
- Las rutas GET históricas y estadísticas no tienen autenticación y responden
  con CORS abierto.
- Con `workers_dev = true`, un despliegue expondría el Worker en una URL pública
  de `workers.dev`. Debe resolverse el control de acceso antes de staging remoto.

## Riesgos y bloqueos

1. Worker y D1 de staging todavía no existen.
2. El UUID cero impide confirmar aislamiento por identidad.
3. No existe una política de acceso para los endpoints GET de staging.
4. La sesión actual tiene permisos amplios; un comando equivocado podría crear
   o modificar recursos.
5. El nombre principal tampoco existe en la cuenta consultada; producción puede
   residir en otra cuenta y no debe inferirse su estado desde este resultado.
6. El runbook anterior contempla backfill contra una fuente remota; no debe
   usarse para esta validación sintética.

## Plan de aislamiento propuesto

Antes de Fase 8.5B se requiere autorización separada para:

1. Identificar y registrar la cuenta Cloudflare destinada a staging.
2. Crear un Worker y un D1 exclusivos con los nombres declarados.
3. Sustituir el UUID cero únicamente por el ID del D1 de staging y verificar que
   no coincide con ningún D1 de producción.
4. Mantener sin rutas, dominios ni cron.
5. Definir acceso privado o temporal para staging antes de exponer `workers.dev`.
6. Cargar exclusivamente fixtures sintéticos; no ejecutar backfill.
7. Revisar el plan y los IDs antes de cualquier migración o despliegue.

## Comandos propuestos, no ejecutados

Estos comandos son una secuencia futura y requieren autorización explícita. Los
valores devueltos deben revisarse antes de continuar.

```sh
npx wrangler d1 create sorteosdominicanos-history-staging-db
npx wrangler d1 migrations apply sorteosdominicanos-history-staging-db --remote --config wrangler.staging.toml
npx wrangler deploy --config wrangler.staging.toml
```

No se propone ejecutar backfill remoto ni copiar D1 de producción.
