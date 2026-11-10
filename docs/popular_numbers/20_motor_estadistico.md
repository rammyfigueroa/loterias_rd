# Motor estadístico de relaciones históricas

## Ubicación y alcance

El motor está en:

`loterias_rd_api/src/statistics/number-transitions.js`

Exporta `calculateNumberTransitions`. No depende de HTTP, rutas, Cloudflare,
D1, Flutter, reloj, aleatoriedad ni estado global. La validación de fechas
reutiliza `parseIsoDate`, una utilidad pura existente.

No se registró ningún endpoint y no se modificó producción.

## Entrada

La función recibe un objeto con:

- `events`: eventos normalizados;
- `coverageRows`: cobertura por fecha y serie;
- `series`: `operatorId` y `drawId` esperados;
- `position`: solo `first`;
- `originNumber`: texto canónico `00` a `99`;
- `from` y `to`: pareja opcional de límites inclusivos;
- `coverageMode`: `verified`, `incomplete` o `all`.

Cada evento exige `eventId`, identidades de serie, posición, fecha, estado y,
para `RESULT_FOUND`, número de dos dígitos. Los estados sin resultado se
registran como advertencia y no se convierten en eventos.

Cada fila de cobertura exige identidades de serie, fecha y uno de los estados
conocidos. El motor no interpreta ausencia de cobertura como continuidad.

## Algoritmo

1. Valida serie, posición, número, rango y modo.
2. Valida y ordena entradas para eliminar dependencia del orden recibido.
3. Deduplica copias equivalentes por identidad estable.
4. Excluye identidades o fechas contradictorias y registra advertencias.
5. Filtra eventos por el rango inclusivo antes de construir pares.
6. Ordena eventos canónicos por fecha e identidad.
7. Conecta cada evento con el siguiente de la misma secuencia.
8. Excluye pares que atraviesen conflictos no resueltos.
9. Clasifica continuidad como verificada, incompleta o desconocida.
10. Filtra por modo de cobertura y número origen.
11. Agrupa por destino, calcula conteos y frecuencia relativa.
12. Ordena por conteo descendente y número ascendente.

## Cobertura

- `VERIFIED`: todas las fechas contienen `RESULT_FOUND` o
  `NO_DRAW_SCHEDULED` confirmado.
- `INCOMPLETE_COVERAGE`: existe `NO_RESULTS_RETURNED` o `FETCH_FAILED`.
- `UNKNOWN_COVERAGE`: falta una fila o existe `UNVERIFIED`, `PENDING` o un
  conflicto de cobertura.

El modo `verified` es predeterminado. `incomplete` sirve para auditar cualquier
transición no verificada y conserva la clasificación exacta. `all` incluye
ambos grupos y reporta subtotales separados.

## Duplicados y correcciones

- Una copia equivalente del mismo `eventId` cuenta una vez.
- Eventos equivalentes con IDs distintos en una fecha cuentan una vez.
- Versiones contradictorias del mismo ID o fecha no se resuelven por selección;
  se excluyen junto con las transiciones que las atraviesan.
- Una corrección canónica debe llegar como el valor vigente del evento estable,
  igual que la fila actual de D1. Recalcular cambia determinísticamente las dos
  transiciones adyacentes cuando corresponda.

## Salida

La respuesta contiene serie, posición, origen, rango efectivo, modo y estado de
cobertura, estado de muestra, apariciones del origen, eventos sin sucesor,
transiciones válidas, métricas de calidad, ranking, advertencias y descargo.

Cada fila incluye:

- `nextNumber`;
- `transitionCount`;
- `relativeFrequency`;
- `lastTransitionDate`.

La frecuencia se redondea a seis decimales. Con denominador cero, la lista queda
vacía y `sampleStatus` es `NO_TRANSITIONS_OBSERVED`.

## Complejidad

Para `E` eventos, `C` filas de cobertura, `K` conflictos y `D` fechas
recorridas:

- tiempo: `O(E log E + C log C + D + E log K)`;
- memoria: `O(E + C + D)` por eventos, cobertura, advertencias y fechas
  bloqueantes.

Los intervalos entre eventos adyacentes recorren el rango cronológico de forma
solapada solo en sus extremos. La búsqueda de conflictos usa fechas ordenadas y
búsqueda binaria.

## Limitaciones

- No valida que `to` sea futura porque el motor no tiene reloj; esa regla
  pertenece a la capa de consulta que recibe una fecha máxima explícita.
- No consulta D1 ni resuelve revisiones históricas; espera eventos canónicos.
- No pagina, cachea ni expone rutas.
- Solo admite primera posición y una serie por cálculo.
- No realiza inferencia, causalidad ni predicción.
