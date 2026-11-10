# Endpoint de transiciones históricas

## Ruta

```http
GET /statistics/number-transitions
```

No está desplegada en producción.

## Parámetros

| Parámetro | Regla |
| --- | --- |
| `operatorId` | Obligatorio; debe formar una serie autorizada exacta |
| `drawId` | Obligatorio; no se aceptan coincidencias por nombre |
| `position` | Obligatorio y exactamente `first` |
| `number` | Obligatorio, exactamente dos dígitos `00`–`99` |
| `from`, `to` | Pareja opcional `YYYY-MM-DD`, límites inclusivos |
| `coverage` | `verified` por defecto; `incomplete` o `all` |
| `limit` | 1–100, predeterminado 25 |
| `cursor` | Opaco y ligado al fingerprint de datos |

Las fechas futuras se comparan con `America/Santo_Domingo`, no con la fecha UTC.
Un rango personalizado fuera de la cobertura disponible se rechaza.

## Respuesta

Incluye:

- `series`: operador, sorteo y posición;
- `originNumber`;
- `requestedRange` y `effectiveRange`;
- `availableCoverage`;
- `coverageMode` y `coverageStatus`;
- apariciones y total de transiciones;
- calidad de muestra;
- conteos, frecuencias observadas y última transición por destino;
- advertencias;
- `dataRevision` con fingerprint;
- paginación;
- descargo no predictivo.

`relativeFrequency` usa el total de transiciones incluidas para el origen como
denominador. No representa probabilidad futura.

## Errores

- `400`: IDs ausentes/no autorizados, posición, número, cobertura, cursor o
  fechas inválidas; rango fuera de cobertura.
- `404`: ruta estadística inexistente.
- `405`: método distinto de GET.
- `503`: binding `HISTORY_DB` ausente.
- `500`: error interno genérico; el detalle permanece en logs.

## Caché y cursor

La caché en memoria tiene máximo 100 entradas y comportamiento LRU. La clave
distingue serie, posición, origen, rango, cobertura y fingerprint. Los cursores
contienen offset y fingerprint; un cursor de otra revisión se rechaza para no
mezclar páginas de snapshots diferentes.

## Ejemplo de forma

```text
/statistics/number-transitions
  ?operatorId=<id-estructurado>
  &drawId=<id-estructurado>
  &position=first
  &number=10
  &coverage=verified
```

Los identificadores se omiten del ejemplo para evitar que la documentación se
confunda con autorización de una serie o entorno específico.
