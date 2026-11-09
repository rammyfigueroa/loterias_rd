# Modelo de evidencia de derechos

## Brecha cerrada

`RightsStatus.authorized` ya no basta para atravesar
`PublishableCatalogGate`. La publicación exige esquema 1.1, evidencia trazable y
un `PublicationContext` con fecha y distribución previstas. Los catálogos 1.0
siguen siendo legibles, pero no publicables.

## RightsEvidence

El modelo registra identificador, fuente, titular, tipo y referencia de la
autorización, fechas de evidencia, inicio, vencimiento y revisión, territorio,
facultades de uso comercial, redistribución y obras derivadas, atribución,
restricciones, estado de revisión, tipo de alcance y referencias exactas de
alcance.

Los tipos de alcance son `fullSource`, `specificFragment`, `table`, `article`,
`image`, `editorialText`, `structuredData` y `other`. Una referencia de
`article` no cubre una tabla. `fullSource` debe referenciar el ID de la fuente;
los alcances parciales deben referenciar el ID exacto del contenido.

## Reglas

- La fuente y toda evidencia referenciada deben existir.
- Titular, referencia documental y alcance no pueden estar vacíos.
- La evidencia debe estar revisada como `approved`; el gate no cambia estados.
- `openLicense` no se interpreta automáticamente como autorización suficiente:
  debe declarar condiciones, facultades y revisión igual que cualquier permiso.
- La fecha de evidencia, revisión e inicio no puede ser futura respecto del
  contexto explícito; el vencimiento no puede haber pasado.
- Una vigencia sin vencimiento requiere justificación escrita.
- Uso comercial y redistribución deben estar permitidos.
- Distribución mundial requiere autorización mundial. Una autorización de RD
  no cubre otros territorios.
- Las restricciones se comparan con las incompatibilidades declaradas por el
  contexto de publicación.
- Cada claim, interpretación o artículo debe enlazar evidencia que cubra cada
  fuente usada y el tipo exacto de contenido.

## Frontera de publicación

`PublishableDreamsCatalog` conserva una copia profunda inmutable de evidencias y
artículos. Solo `PublishableCatalogGate.evaluate(..., context: ...)` puede crear
el wrapper. Búsqueda y descifrador continúan operando mediante ese wrapper.

Archivos principales:

- `lib/features/dreams_numbers/domain/dreams_catalog.dart`
- `lib/features/dreams_numbers/domain/catalog_validation.dart`
- `lib/features/dreams_numbers/application/publishable_catalog.dart`
- `lib/features/dreams_numbers/data/dreams_catalog_loader.dart`
- `docs/dreams_numbers/dreams_catalog.schema.json`
