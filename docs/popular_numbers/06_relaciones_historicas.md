# Relaciones históricas entre números

## Viabilidad con datos existentes

El repositorio ya conserva resultados por `operator_id`, `draw_id`, fecha y
primera posición en `loterias_rd_api/migrations/0001_gana_mas_history.sql`.
`loterias_rd_api/src/statistics/service.js` filtra obligatoriamente por operador
y sorteo. Flutter transmite esos identificadores y rangos en
`first_prize_statistics_remote_source.dart`.

La base permite investigar, por serie independiente, qué valor apareció en la
siguiente observación después de un valor seleccionado. No se implementó esa
consulta en esta fase.

## Definición propuesta

Unidad: transición entre dos sorteos consecutivos y verificables de la misma
serie y la misma posición. Para un número origen `x`, contar el número destino
del siguiente sorteo. Mostrar:

- observaciones de origen;
- conteo por destino;
- frecuencia relativa con denominador visible;
- primera y última fecha;
- cobertura y fechas no verificadas;
- intervalo calendario y/o número de sorteos, claramente diferenciados.

## Reglas de calidad

- No cruzar operadores, sorteos, tandas o posiciones.
- No crear transición a través de una fecha con cobertura desconocida.
- Ordenar por fecha canónica y resolver revisiones del proveedor.
- Exigir tamaño mínimo antes de clasificar y mostrar todos los destinos,
  incluido cero.
- Comparar con una línea base y mostrar incertidumbre; no seleccionar solo los
  resultados llamativos.

## Sesgos y límites

Frecuencias distintas, cierres, cambios de proveedor, datos faltantes y muchas
comparaciones pueden generar patrones aparentes. Una relación temporal no es
causal y no modifica necesariamente la probabilidad del siguiente sorteo.

## Hipótesis

La infraestructura existente puede reutilizar D1, paginación, cobertura,
selector de serie y rango. Conviene un endpoint estadístico nuevo solo después
de aprobar una especificación y pruebas; no almacenar asociaciones culturales
en las tablas históricas.
