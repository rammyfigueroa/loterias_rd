# Especificación de Relaciones Históricas entre Números

## 1. Alcance

La función describe qué número de primera posición apareció en el siguiente
sorteo válido de la misma serie después de un número origen. Es una estadística
retrospectiva. No estima probabilidades futuras, no incorpora tablas populares
y no combina series.

La primera versión admite exclusivamente:

- series autorizadas en `loterias_rd_api/src/history/constants.js`;
- posición `first`, almacenada como `first_number`;
- números canónicos `00` a `99`;
- fechas civiles de `America/Santo_Domingo` en formato `YYYY-MM-DD`.

## 2. Infraestructura reutilizable

| Componente existente | Uso propuesto |
|---|---|
| `first_prize_results` | Eventos canónicos, identificadores, serie, fecha y primer número |
| `coverage` | Determinar continuidad verificada o incompleta |
| `result_revisions` | Trazabilidad de correcciones e invalidación de caché |
| `requireAuthorizedSeries` | Exigir `operatorId` y `drawId` exactos |
| `parseDateRange` | Validar rango completo, ordenado y no futuro |
| `normalizeResults` | Orden, formato, deduplicación defensiva y rechazo de mezcla |
| `loadStatisticsSnapshot` | Lectura por serie/rango y fingerprint de resultados/cobertura/revisiones |
| Paginación estadística | `limit`, cursor opaco y metadatos de página |
| `StatisticsDrawOption` | Selector estructurado de serie en Flutter |
| Controles Desde/Hasta | Selección de rango y `Todo el historial` |
| IDs de solicitud del controlador | Ignorar respuestas tardías tras cambiar filtros |

No se reutilizará `calculateConsecutiveIntervals` como motor de transición: ese
código agrupa apariciones consecutivas del mismo número, mientras esta función
conecta eventos consecutivos de cualquier número.

## 3. Modelo de evento

Un `HistoricalNumberEvent` lógico contiene:

- `eventId`: `first_prize_results.id`, identidad interna estable;
- `providerResultId`: identificador vigente del proveedor;
- `operatorId`;
- `drawId`;
- `position`: valor fijo `first` en la primera versión;
- `drawDate`;
- `number`;
- `updatedAt` y `checksum` para trazabilidad técnica.

El identificador interno es preferible para la relación porque una revisión
puede cambiar `provider_result_id` conservando la misma fila. La API pública no
necesita exponer `raw_payload` ni checksums.

## 4. Definición formal de transición

Para una serie `S` y rango inclusivo `[from, to]`, se ordenan los eventos
canónicos por `(draw_date ASC, id ASC)`. Para cada par adyacente `(E_i, E_i+1)`:

1. ambos pertenecen al mismo `operatorId`, `drawId` y `position`;
2. ambos están dentro de `[from, to]`;
3. `E_i+1` es el siguiente evento almacenado de esa serie dentro de la
   secuencia, no necesariamente del día siguiente;
4. la continuidad desde la fecha origen hasta la fecha destino se clasifica con
   `coverage`;
5. la transición es `E_i.number -> E_i+1.number`.

El último evento no produce transición. Un evento anterior a `from` no se usa
como origen y uno posterior a `to` no se usa como destino.

## 5. Reglas cronológicas

1. **Orden:** fecha ISO ascendente y luego ID interno.
2. **Fecha duplicada:** la restricción `UNIQUE(draw_id, draw_date)` impide dos
   eventos de la misma serie y fecha. Un duplicado idéntico se deduplica
   defensivamente; uno conflictivo produce error de integridad.
3. **Fecha faltante:** no se inventa evento. La transición al siguiente evento
   se marca incompleta si falta cobertura verificable en cualquier fecha del
   intervalo.
4. **Sin sorteo/cancelado:** solo `NO_DRAW_SCHEDULED` respaldado por verificación
   se considera continuidad válida. Una cancelación no verificada queda
   bloqueante.
5. **Corrección:** se usa el valor canónico más reciente y se conserva la
   revisión. El fingerprint debe invalidar resultados derivados.
6. **Sin resultado:** no constituye evento. `NO_RESULTS_RETURNED`, `UNVERIFIED`,
   `FETCH_FAILED`, `PENDING` o ausencia de cobertura bloquean verificación.
7. **Último evento:** aumenta apariciones del origen, pero no el denominador de
   transiciones porque carece de sucesor dentro del rango.
8. **Rango:** límites inclusivos; ambos eventos deben estar dentro.
9. **Cobertura parcial:** se informa y se excluye del modo `verified`.
10. **Diferencias de calendario:** se resuelven por cobertura específica de cada
    `drawId`, nunca suponiendo periodicidad diaria.

## 6. Filtros

Obligatorios:

- `operatorId`;
- `drawId`;
- `position=first`;
- `number=00..99`.

Opcionales como pareja:

- `from` y `to`;
- `coverage=verified|incomplete|all`, con `verified` por defecto;
- `limit` y `cursor` para resultados siguientes.

No se ofrece modo “Ambas” en esta herramienta. Una consulta representa una sola
serie. Una comparación futura debe hacer consultas independientes y conservar
los denominadores separados.

## 7. Cobertura y estados

Cada transición tendrá `VERIFIED` o `INCOMPLETE_COVERAGE` y, si corresponde,
`blockingDates`. La respuesta agregada incluirá cobertura disponible, eventos
analizados, transiciones verificadas/incompletas y fechas no verificadas.

Si el número origen no aparece, la respuesta es válida y vacía. Si aparece solo
como último evento, `originAppearances` será positivo pero
`totalTransitions=0`.

## 8. Riesgos

- Un tamaño pequeño produce porcentajes inestables.
- Muchas consultas pueden destacar coincidencias casuales.
- Corregir un resultado puede cambiar dos transiciones adyacentes.
- La política de continuidad por fecha es conservadora y depende de calidad de
  `coverage`.
- Los porcentajes observados no son probabilidades de futuros sorteos.
