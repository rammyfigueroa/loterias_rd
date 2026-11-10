# Contrato Flutter y Worker para Relaciones Históricas

Fecha: 2026-11-09.

## Solicitud implementada por el Worker

```http
GET /statistics/number-transitions
```

Parámetros:

| Campo | Estado | Regla |
| --- | --- | --- |
| `operatorId` | obligatorio | pareja estructurada autorizada |
| `drawId` | obligatorio | no se identifica por texto |
| `position` | obligatorio | `first` |
| `number` | obligatorio | `00`–`99` |
| `from`, `to` | pareja opcional | ISO, inclusivos, dentro de cobertura |
| `coverage` | opcional | `verified`, `incomplete`, `all` |
| `limit` | opcional | 1–100, 25 por defecto |
| `cursor` | opcional | opaco y ligado al fingerprint |

Flutter ya conserva todos los filtros funcionales salvo `limit` y `cursor`.

## Respuesta Worker

La respuesta contiene:

- `series`: IDs, nombres y posición;
- `originNumber`;
- `requestedRange`;
- `effectiveRange`;
- `availableCoverage`;
- `coverageMode` y `coverageStatus`;
- `sampleStatus`;
- `originAppearances` y `originEventsWithoutSuccessor`;
- `totalTransitions`;
- `quality`;
- `results`;
- `warnings` estructuradas;
- `dataRevision` con fingerprint y conteos;
- `cacheStatus`;
- `count`, `total`, `hasMore`, `nextCursor`;
- `disclaimer`.

## Compatibilidad actual

| Área | Flutter local | Worker | Acción futura |
| --- | --- | --- | --- |
| Serie | `StatisticsDrawOption` | objeto `series` | mapear y verificar IDs recibidos |
| Número | compatible | `originNumber` | rechazar discrepancia con consulta |
| Rango | un solo `range` | solicitado, efectivo y disponible | modelar los tres |
| Cobertura | enum solicitado | modo y estado observado | separar modo de estado |
| Calidad | subconjunto | métricas ampliadas | añadir campos sin perder desconocidos |
| Destinos | compatible | compatible | validar 00–99, conteo y frecuencia |
| Advertencias | `List<String>` | objetos con código y detalle | crear modelo estructurado |
| Revisión | ausente | fingerprint y metadatos | modelar para caché/información |
| Paginación | ausente | cursor opaco | implementar agregación segura |
| Caché | respuesta completa local | caché/fingerprint servidor | invalidar por fingerprint/TTL |
| Estado de muestra | inferido por lista | explícito | usar `sampleStatus` |

## Incompatibilidades bloqueantes

1. `warnings` no puede decodificarse como texto sin perder código y detalle.
2. Flutter no representa `unknownCoverageTransitions`, conflictos o exclusiones.
3. Flutter no distingue rango solicitado de rango efectivo.
4. Flutter no conoce cobertura disponible ni revisión de datos.
5. Flutter no consume páginas ni detecta cursores repetidos.
6. El repositorio sintético no modela errores HTTP o de contrato.
7. No hay parser que compruebe tipos, límites y consistencia matemática.

## Reglas del parser futuro

- Exigir objeto JSON y campos esenciales.
- Rechazar IDs o número origen distintos de la consulta.
- Validar fechas ISO y límites inclusivos.
- Validar números `00`–`99`, conteos no negativos y frecuencia `0..1`.
- No exigir que la suma de la página sea 1; puede haber más páginas.
- Exigir que `transitionCount <= totalTransitions`.
- Tratar campos nuevos desconocidos como compatibles, pero no ocultar la falta
  de campos esenciales.
- Conservar advertencias estructuradas y descargo del servidor.
- Detener paginación ante cursor repetido, revisión distinta o máximo de páginas.

## Errores

El futuro cliente debe distinguir:

- configuración ausente;
- transporte/DNS/TLS;
- timeout;
- `400` de filtros;
- `401/403` de superficie no autorizada;
- `404` de versión/ruta;
- `429` con reintento posterior;
- `5xx` transitorio;
- JSON o contrato inválido.

La UI debe presentar mensajes estables en español y no mostrar cuerpo interno,
headers, IDs sensibles o trazas.

## Versionado

Antes de conexión pública debe definirse una versión de contrato, mediante ruta
o campo de esquema. Flutter debe aceptar cambios aditivos dentro de una versión
y rechazar cambios incompatibles con un error controlado.
