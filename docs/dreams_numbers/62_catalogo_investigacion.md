# Estructura del catálogo de investigación

## Separación de producción

Este catálogo es un registro de trabajo, no el catálogo JSON 1.2.0 de la app.
Debe almacenarse fuera de assets y no pasar al `PublishableCatalogGate` hasta
una transformación revisada y aprobada.

## Entidades propuestas

### `research_sources`

Participantes anónimos y fuentes documentales. Conserva tipo, acceso,
consentimiento, derechos y agrupación de fuente común.

### `research_records`

Respuesta o pasaje original autorizado, contexto, fecha, geografía declarada y
procedencia inmediata.

### `research_associations`

Vincula un registro con `number`, `symbol_original` y una normalización
provisional. Permite múltiples números por símbolo y múltiples símbolos por
número.

### `research_variants`

Conserva relaciones `exact`, `synonym`, `related`, `narrower`, `broader` o
`phrase`, siempre con revisión y justificación.

### `research_reviews`

Registra revisión de independencia, lingüística, cultural, editorial, derechos
y privacidad sin sobrescribir la evidencia.

### `research_conflicts`

Agrupa asociaciones incompatibles y explica su naturaleza sin elegir una como
ganadora.

## Vista 00-99

La interfaz de investigación puede generar cien casillas virtuales desde `00`
hasta `99`. Una casilla sin evidencia se muestra vacía; no necesita un registro
ficticio. Cada casilla puede enlazar cero, una o varias asociaciones.

## Estados

- Evidencia: `unverified`, `supported`, `disputed`, `verified`, `rejected`.
- Independencia: `unknown`, `independent`, `shared_source`, `dependent`,
  `duplicate`.
- Consentimiento: `not_collected`, `limited`, `granted`, `withdrawn`.
- Derechos: `unknown`, `permissionPending`, `authorized`, `restricted`,
  `rejected`.
- Editorial: `draft`, `review`, `approved`, `rejected`.
- Clasificación cultural: `documented`, `corroborated`, `conflict`,
  `insufficient`.

## Restricciones de integridad

- `number` es nulo o una cadena `00`-`99`.
- IDs únicos y referencias existentes.
- Ningún registro de testimonio sin consentimiento válido para el uso previsto.
- Una asociación retirada no participa en análisis ni exportación.
- `corroborated` exige al menos dos grupos de fuente independientes revisados.
- Un conflicto no puede eliminar observaciones originales.
- Ningún estado de derechos se infiere desde frecuencia o acceso público.

## Transformación futura a JSON 1.2.0

| Investigación | Producción futura | Condición previa |
|---|---|---|
| Fuente documental o corpus consentido | `Source` | Procedencia, verificación y derechos revisados |
| Símbolo normalizado | `CatalogEntry` | Definición original aprobada |
| Asociación individual | `DocumentaryClaim` | Fuente, número y evidencia verificadas |
| Variante | `TermVariant` | Relación lingüística revisada |
| Evidencia de consentimiento/licencia | `RightsEvidence` | Base jurídica, alcance y revisión completos |
| Contradicción | `ConflictGroup` | Claims preservados y explicación aprobada |

La exportación no es automática. Un elemento `documented` o `corroborated`
puede seguir bloqueado por derechos, privacidad o revisión editorial.
