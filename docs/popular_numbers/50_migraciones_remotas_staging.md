# Migraciones remotas de staging

Fecha: 2026-11-09.

## Recurso autorizado

- Cuenta: `f171b568e3a3a203a09ef2fd6e337a2c`.
- D1: `sorteosdominicanos-db-staging`.
- UUID: `f31aac48-f437-4fd7-9691-a7e976010dc6`.
- Binding local: `HISTORY_DB`.
- Configuración: `loterias_rd_api/wrangler.staging.toml`.
- Región: `ENAM`.

## Verificación previa

Antes de escribir se confirmó:

- cuenta activa exacta;
- nombre y UUID exactos;
- configuración de staging explícita;
- base remota accesible;
- cero tablas funcionales;
- ausencia de resultados o datos históricos;
- lista exacta y ordenada de 0001 y 0002 pendientes.

La inspección de `sqlite_master` mostró únicamente objetos internos de D1:
`d1_migrations`, `_cf_KV`, `sqlite_sequence` y el índice automático de
`d1_migrations`. No había esquema funcional inesperado.

## Comando ejecutado

Desde `loterias_rd_api`:

```sh
WRANGLER_SEND_METRICS=false npx --no-install wrangler d1 migrations apply sorteosdominicanos-db-staging --remote --config wrangler.staging.toml
```

No se utilizó configuración implícita, binding de producción ni script general
de despliegue.

## Resultado

Wrangler 4.155.0 aplicó en orden:

1. `0001_gana_mas_history.sql`: 16 comandos, correcto.
2. `0002_national_history.sql`: 2 comandos, correcto.

No hubo errores SQL. El historial remoto registró ambos archivos con fecha
`2026-11-10 01:25:06` UTC y una comprobación posterior informó
`No migrations to apply`.

## Esquema remoto

Tablas funcionales:

1. `operators`.
2. `draws`.
3. `first_prize_results`.
4. `coverage`.
5. `result_revisions`.
6. `backfill_state`.

Wrangler/D1 también mantiene tablas internas como `d1_migrations`, `_cf_KV` y
`sqlite_sequence`. `d1 info` reportó 7 tablas según el conteo de plataforma.

Índices explícitos:

- `idx_draws_operator`;
- `idx_first_prize_draw_date`;
- `idx_first_prize_number_date`;
- `idx_coverage_draw_date`;
- `idx_coverage_status`;
- `idx_revisions_result`.

Los índices automáticos de claves primarias y restricciones `UNIQUE` también
están presentes.

## Integridad y contenido

Las claves foráneas fueron verificadas para sorteos, resultados, revisiones y
estado de backfill. Las restricciones de unicidad y `CHECK` permanecen definidas
por el esquema auditado.

Contenido posterior:

- operadores: 1 (`Nacional`);
- sorteos: 2 (`Gana Más` y `Lotería Nacional`);
- resultados históricos: 0;
- cobertura: 0;
- revisiones: 0;
- estados de backfill: 0.

Los únicos registros funcionales son metadatos estructurados insertados por las
migraciones. No contienen datos personales ni resultados históricos.

## Aislamiento

- Worker `api`: misma versión activa `9e4621b3-1d47-433a-b6e8-25c22de74d87`,
  sin binding D1.
- Worker `sorteosdominicanos-app`: mismo despliegue activo.
- Worker `sorteosdominicanos-api-staging`: no existe.
- No se crearon ni desplegaron Workers.
- No se modificaron bindings, DNS, rutas, Access, variables o secretos.
- No se cargaron fixtures ni se ejecutó backfill.

## Próximo paso recomendado

Preparar y auditar un fixture sintético idempotente en una fase independiente.
No cargarlo todavía y no desplegar el Worker hasta aprobar Cloudflare Access.
