# Reglas de validación implementadas

## Capas

La validación se ejecuta en capas separadas:

1. `jsonDecode`: sintaxis JSON.
2. `DreamsCatalogLoader._validateKnownFields`: estructura y propiedades conocidas.
3. Factories `fromJson`: tipos, campos requeridos y enums.
4. `CatalogValidator.validate`: formato e integridad referencial.
5. `CatalogValidator.validateForPublication`: verificación, derechos y aprobación.
6. `PublishableCatalogGate`: única construcción de `PublishableDreamsCatalog`.

Un JSON válido no se considera publicable automáticamente.

## Validación estructural

`CatalogValidator.validate` comprueba:

- Versión exacta `1.0.0`.
- Locale no vacío.
- `generatedAt` como fecha-hora ISO-8601 con zona.
- Fechas de fuente como `YYYY-MM-DD` válidas.
- Formato y unicidad de IDs por colección.
- Variantes duplicadas dentro de una entrada.
- Referencias de afirmaciones a entradas y fuentes existentes.
- Números como cadenas `00`-`99`.
- Referencias de interpretaciones a entradas y fuentes existentes.
- Ausencia de referencias de fuente duplicadas en interpretaciones.
- Mínimo de dos afirmaciones por conflicto, sin repeticiones ni IDs inexistentes.
- Propiedades JSON desconocidas en la raíz y objetos anidados.

El cargador no ejecuta un motor JSON Schema externo, pero replica en Dart las
restricciones relevantes usadas por el modelo actual. El esquema sigue siendo el
contrato documental versionado.

## Política estricta de publicación

Solo se acepta:

- `metadata.editorialStatus == PublicationStatus.approved`.
- `Source.rightsStatus == RightsStatus.authorized`.
- `Source.verificationStatus == VerificationStatus.verified`.
- `DocumentaryClaim.verificationStatus == VerificationStatus.verified`.
- `EditorialInterpretation.publicationStatus == PublicationStatus.approved`.
- `EditorialInterpretation.verificationStatus == VerificationStatus.verified`.
- Al menos una referencia documental válida por interpretación.

`supported`, `disputed`, `unverified` y `rejected` no autorizan publicación.
`openLicense`, `permissionPending`, `unauthorized`, `restricted` y `unknown` se
rechazan en esta política. El modelo todavía no registra condiciones suficientes
para demostrar que una licencia abierta permite el uso comercial previsto; por
eso `openLicense` no se eleva automáticamente a autorización.

La aprobación editorial no sustituye verificación ni derechos.

## Tipo seguro

`PublishableDreamsCatalog`:

- Tiene constructor privado.
- Solo se produce desde `PublishableCatalogGate.evaluate`.
- Recibe una copia profunda del catálogo aprobado.
- Expone colecciones no modificables.
- No expone el `DreamsCatalog` interno.
- Proporciona búsqueda y análisis local sobre la copia validada.

Las pantallas Tabla, Diccionario y Descifrador aceptan exclusivamente
`PublishableDreamsCatalog?`. La ausencia de catálogo conserva los estados vacíos.
No existe una referencia directa a `DreamsCatalog` en la capa de presentación.

## Motores internos

`DreamsCatalogSearch` y `DreamDescriptionAnalyzer` continúan aceptando
`DreamsCatalog` para pruebas de dominio. Producción solo puede invocarlos mediante
los métodos `search` y `analyze` del envoltorio seguro.

## Riesgos residuales

- `RightsStatus.authorized` no contiene documento, alcance, territorio, vigencia
  ni responsable de la autorización; esos datos deben registrarse antes de usar
  contenido real.
- El validador Dart y el JSON Schema deben mantenerse sincronizados manualmente.
- Los modelos de dominio crudos siguen siendo públicos para pruebas y herramientas
  internas; la protección se concentra en la frontera de presentación.
- No existe todavía catálogo real autorizado ni prueba con evidencia jurídica.
