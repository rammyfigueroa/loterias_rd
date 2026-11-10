# Integración local del motor con Worker y D1

Fecha: 2026-11-09.

## Arquitectura

La integración conserva tres responsabilidades separadas:

1. `number-transitions.js`: motor puro, sin cambios en esta fase.
2. `number-transitions-service.js`: consulta D1, cobertura, revisión, caché y
   adaptación al motor.
3. `routes.js`: contrato HTTP, validación de parámetros, fecha dominicana y
   paginación.

`src/index.js` ya delegaba las rutas `/statistics/*` a `routes.js`; solo fue
necesario registrar el nuevo path en `isStatisticsPath`.

## Consulta canónica

La consulta exige `operator_id` y `draw_id` en todas las lecturas. Los resultados
se ordenan por `draw_date ASC, id ASC` y obtienen únicamente la fila canónica
vigente de `first_prize_results`. No se leen revisiones antiguas como eventos.

Campos de resultados:

- identidad interna y del proveedor;
- operador y sorteo;
- fecha;
- primera posición;
- checksum y fecha de actualización.

La cobertura se consulta por la misma serie y rango. `NO_DRAW_SCHEDULED` solo se
adapta como continuidad verificada cuando `verification_source` no es nulo. Sin
esa evidencia se entrega al motor como `UNVERIFIED`.

## Integridad

- `UNIQUE(draw_id, draw_date)` evita dos resultados canónicos para una fecha.
- `UNIQUE(provider_result_id)` evita duplicar una identidad del proveedor.
- El motor mantiene deduplicación y rechazo de conflictos como defensa adicional.
- Una corrección actualiza la fila canónica y agrega `result_revisions`.
- No se infiere sorteo diario por ausencia de fila.
- No se crean eventos para estados sin resultado.

## Cobertura

El servicio calcula límites disponibles desde `coverage`. Un rango personalizado
fuera de esos límites devuelve error de validación. Sin rango personalizado se
usa toda la cobertura disponible; si no existe cobertura, se usan límites de
resultados solo para producir una muestra conservadora, nunca para afirmar
continuidad.

La respuesta separa:

- rango solicitado;
- rango efectivo;
- cobertura disponible;
- estados verificados, incompletos y desconocidos.

## Revisión de datos

El fingerprint SHA-256 incluye fecha dominicana, conteos y límites de resultados,
última actualización, conteos de cobertura por estado, última comprobación y
conteo/fecha de revisiones. Cambiar un resultado, cobertura o revisión produce
otra huella e invalida la respuesta derivada.

## Índices

Se reutilizan:

- `idx_first_prize_draw_date`;
- `idx_first_prize_number_date`;
- `idx_coverage_draw_date`;
- `idx_revisions_result`.

No se creó migración ni índice nuevo. La medición local no justificó cambios de
esquema.

## Limitaciones

- El cálculo carga el rango en memoria.
- La integridad histórica depende de que las escrituras sigan pasando por el
  repositorio y registren revisiones.
- La evidencia de `NO_DRAW_SCHEDULED` se representa como texto no nulo; una fase
  futura podría exigir un esquema de evidencia más rico.
- Esta integración permanece local y no modifica D1 remota.
