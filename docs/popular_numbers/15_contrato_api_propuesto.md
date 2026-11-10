# Contrato API propuesto

## Endpoint

```http
GET /statistics/number-transitions
```

Se recomienda `/statistics`, no `/stats`, para mantener el prefijo existente.
El endpoint no se implementa en esta fase.

## Parámetros

| Parámetro | Requerido | Regla |
|---|---:|---|
| `operatorId` | Sí | Debe corresponder a una serie autorizada |
| `drawId` | Sí | Debe formar pareja exacta con `operatorId` |
| `position` | Sí | Solo `first` en v1 |
| `number` | Sí | Dos dígitos, `00` a `99`; se puede normalizar `0` a `00` si se reutiliza `validateFirstNumber` |
| `from` | Condicional | `YYYY-MM-DD`; obligatorio si aparece `to` |
| `to` | Condicional | `YYYY-MM-DD`; obligatorio si aparece `from`, no futuro |
| `coverage` | No | `verified` por defecto; `incomplete` o `all` para diagnóstico |
| `limit` | No | Predeterminado 25, máximo 100 |
| `cursor` | No | Cursor opaco del ranking estable |

Los rangos son inclusivos y ambos eventos de cada transición deben estar dentro.

## Orden de resultados

1. `transitionCount` descendente;
2. `nextNumber` ascendente.

El cursor debe representar un snapshot estable o invalidarse cuando cambie el
fingerprint. No debe ser un simple offset reutilizable sobre datos modificados
sin advertencia.

## Respuesta 200 conceptual

```json
{
  "operatorId": "6966a6d1ea7015c3b8a3d477",
  "drawId": "6966a6d1ea7015c3b8a3d482",
  "drawName": "Gana Más",
  "position": "first",
  "originNumber": "24",
  "range": {
    "from": "2026-01-01",
    "to": "2026-06-30",
    "custom": true,
    "boundsInclusive": true
  },
  "coverageMode": "verified",
  "originAppearances": 8,
  "totalTransitions": 7,
  "quality": {
    "firstAvailableDate": "2026-01-01",
    "lastAvailableDate": "2026-06-30",
    "eventsAnalyzed": 170,
    "verifiedTransitions": 165,
    "incompleteCoverageTransitions": 4,
    "originEventsWithoutSuccessor": 1,
    "unverifiedDateCount": 1,
    "unverifiedDates": []
  },
  "count": 2,
  "total": 2,
  "hasMore": false,
  "nextCursor": null,
  "results": [
    {
      "nextNumber": "31",
      "transitionCount": 2,
      "relativeFrequency": 0.285714,
      "lastTransitionDate": "2026-06-10"
    },
    {
      "nextNumber": "07",
      "transitionCount": 1,
      "relativeFrequency": 0.142857,
      "lastTransitionDate": "2026-05-04"
    }
  ],
  "warnings": [],
  "disclaimer": "This analysis describes observed historical transitions and does not predict future results."
}
```

Los valores son exclusivamente ejemplos de forma, no resultados reales.
`relativeFrequency` se entrega como fracción `0..1`; Flutter decide el formato
porcentual. La suma puede ser menor que 1 en páginas parciales, pero el
denominador siempre es `totalTransitions` de la consulta completa.

## Detalle opcional futuro

Un endpoint separado puede listar ocurrencias auditables:

```http
GET /statistics/number-transitions/{nextNumber}/occurrences
```

Reutilizaría los mismos filtros y devolvería `sourceEventId`, `sourceDate`,
`targetEventId`, `targetDate`, estado de cobertura y fechas bloqueantes. No es
necesario para el primer endpoint y no debe exponer payloads del proveedor.

## Errores

| HTTP | Condición | Mensaje estable propuesto |
|---:|---|---|
| 400 | Faltan IDs | `operatorId and drawId are required.` |
| 400 | Serie no autorizada | `The requested operator and draw series is not enabled.` |
| 400 | Posición distinta | `position must be first.` |
| 400 | Número inválido | `number must be between 00 and 99.` |
| 400 | Solo un límite | `from and to must be provided together.` |
| 400 | Rango invertido | `from must not be after to.` |
| 400 | Fecha futura | `to must not be in the future.` |
| 400 | Cursor inválido | `cursor is invalid.` |
| 503 | Falta D1 | `Historical database is not configured.` |
| 500 | Error no esperado | Mensaje genérico; detalle solo en logs |

## Caché

Clave lógica:

```text
operatorId:drawId:position:number:from|*:to|*:coverage
```

La validez depende del fingerprint actual de resultados, cobertura, revisiones y
fecha dominicana. Para evitar crecimiento sin límite, la implementación futura
debe definir máximo de entradas o TTL/LRU; el mapa actual no es una política de
capacidad.
