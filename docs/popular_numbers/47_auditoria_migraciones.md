# Auditoría de migraciones D1

Fecha: 2026-11-09.

## Inventario

Directorio configurado: `loterias_rd_api/migrations`.

| Orden | Archivo | Propósito |
| ---: | --- | --- |
| 1 | `0001_gana_mas_history.sql` | Crear esquema histórico, índices y metadatos iniciales de Nacional/Gana Más |
| 2 | `0002_national_history.sql` | Incorporar la serie independiente Lotería Nacional |

No existen otros archivos SQL, esquemas alternativos, seeds o fixtures SQL en
el backend. Los fixtures de integración están definidos en JavaScript y usan
una D1 efímera.

## Migración 0001

### Objetos creados

Tablas funcionales:

1. `operators`.
2. `draws`.
3. `first_prize_results`.
4. `coverage`.
5. `result_revisions`.
6. `backfill_state`.

Índices explícitos:

- `idx_draws_operator`;
- `idx_first_prize_draw_date`;
- `idx_first_prize_number_date`;
- `idx_coverage_draw_date`;
- `idx_coverage_status`;
- `idx_revisions_result`.

### Restricciones y dependencias

- `draws.operator_id` referencia `operators.id`.
- Resultados referencian operador y sorteo.
- Revisiones referencian el resultado canónico.
- Backfill referencia el sorteo.
- `provider_result_id` es único.
- La pareja `draw_id, draw_date` es única en resultados.
- La pareja `draw_id, coverage_date` es única en cobertura.
- `first_number` exige dos dígitos.
- Estados de cobertura, backfill y `enabled` tienen listas o valores válidos.

### Escrituras incluidas

Inserta un operador `Nacional` y el sorteo `Gana Más` con IDs estructurados. No
inserta resultados, cobertura, revisiones o backfill. El campo `source` contiene
la URL documental del proveedor; aplicar la migración no realiza una consulta
de red.

### Riesgo destructivo e idempotencia

- Sin `DROP`, `DELETE`, `ALTER TABLE` o actualizaciones masivas.
- No es idempotente como SQL aislado: usa `CREATE TABLE` sin `IF NOT EXISTS` e
  inserciones sin conflicto.
- Sí es segura bajo el gestor de migraciones de Wrangler, que registra el
  archivo en `d1_migrations` y no volvió a ofrecerlo tras aplicarlo localmente.
- Debe aplicarse solo a una base vacía o cuyo historial de migraciones haya sido
  auditado.

## Migración 0002

Inserta Lotería Nacional en `draws`, por lo que depende de `operators` y `draws`
creadas y pobladas por 0001. No crea tablas o índices.

Usa `ON CONFLICT(id) DO UPDATE` para actualizar únicamente nombre, ruta de
primera posición, fecha fuente, estado habilitado y `updated_at` del sorteo con
ese ID. No contiene operaciones destructivas ni actualizaciones sin filtro.

Es compatible con una base vacía después de 0001. Como SQL aislado es
repetible para el ID de Lotería Nacional, aunque cambia `updated_at`; Wrangler
evita reaplicarla cuando ya figura en `d1_migrations`.

## Dependencias de `/statistics/number-transitions`

El endpoint consulta directamente:

- `draws`: valida serie habilitada y `first_position_path`;
- `first_prize_results`: eventos canónicos y límites de resultados;
- `coverage`: rango, continuidad y calidad;
- `result_revisions`: fingerprint e invalidación de caché.

Dependencias indirectas:

- `operators`: integridad referencial de series y resultados;
- índices de resultados, cobertura y revisiones: rendimiento y orden;
- restricciones de unicidad: evitan identidades o fechas canónicas duplicadas.

`backfill_state` no es leído por este endpoint, pero forma parte del esquema
histórico y del repositorio de backfill. No debe eliminarse de la migración.

## Aplicación local auditada

Se creó una D1 efímera bajo `/tmp/sorteos-d1-audit.b8O5L8` y se aplicaron ambas
migraciones con `--local`. Wrangler ejecutó 16 comandos para 0001 y 2 para 0002.

Resultado:

- seis tablas funcionales y seis índices explícitos;
- tablas internas `_cf_METADATA`, `d1_migrations` y `sqlite_sequence`;
- un operador y dos sorteos habilitados;
- cero resultados, cobertura y revisiones;
- claves foráneas visibles mediante `PRAGMA foreign_key_list`;
- segunda consulta: `No migrations to apply`.

No se utilizó la D1 remota durante esta validación.

## Pruebas

- Motor puro: 26/26.
- Integración D1 local: 21/21.
- Backend completo: 84/84.

La integración aplica las dos migraciones a una D1 efímera, carga fixtures
sintéticos y valida consultas, cobertura, correcciones, fingerprint, caché,
paginación, series y rangos. El aviso `punycode` procede de Wrangler/Node y no
alteró resultados.

## Riesgos para aplicación remota

1. Aplicar en una cuenta, UUID o configuración incorrectos.
2. Encontrar tablas o historial `d1_migrations` inesperados.
3. Reaplicar SQL manualmente fuera del gestor de migraciones.
4. Interrumpir 0001 antes de que Wrangler complete su transacción/registro.
5. Confundir los metadatos estructurados insertados con resultados reales.
6. Avanzar a fixtures o backfill sin una autorización independiente.
