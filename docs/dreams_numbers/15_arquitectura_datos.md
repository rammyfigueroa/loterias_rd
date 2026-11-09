# Arquitectura de datos implementada

## Alcance verificado

Este documento reconstruye la arquitectura existente a partir del código local.
No describe una arquitectura prevista ni autoriza contenido editorial.

El módulo se encuentra en `loterias_rd_app/lib/features/dreams_numbers/` y está
dividido en:

- `domain/`: modelos y validación estructural/editorial.
- `data/`: lectura y conversión de JSON local.
- `application/`: normalización, búsqueda, análisis y frontera publicable.
- `presentation/`: navegación, pantallas, estados y widgets.

No existe repositorio remoto, endpoint, binding de Worker ni asset de catálogo de
producción para este módulo.

## Agregado de catálogo

`domain/dreams_catalog.dart` define `DreamsCatalog`, compuesto por:

- `CatalogMetadata metadata`.
- `List<Source> sources`.
- `List<CatalogEntry> entries`.
- `List<DocumentaryClaim> claims`.
- `List<EditorialInterpretation> interpretations`.
- `List<ConflictGroup> conflictGroups`.

Las afirmaciones numéricas están separadas de las entradas y de las
interpretaciones editoriales. Una entrada puede conservar varias afirmaciones,
incluidos números contradictorios. `claimsFor` recupera las afirmaciones sin
fusionarlas y `conflictsForClaims` conserva los grupos de conflicto.

## Modelos y relaciones

- `Source` conserva procedencia, fechas, jurisdicción, derechos y verificación.
- `CatalogEntry` contiene término canónico, categoría, descripción y variantes.
- `TermVariant` distingue relación, contexto y locale.
- `DocumentaryClaim` relaciona una entrada, un número `00`-`99` y una fuente.
- `EditorialInterpretation` permanece separada de las afirmaciones documentales.
- `ConflictGroup` referencia dos o más afirmaciones.
- `CatalogMetadata` versiona esquema y catálogo y registra estado editorial.

Los enums reales son:

- `RightsStatus`: `authorized`, `openLicense`, `permissionPending`,
  `unauthorized`, `restricted`, `unknown`.
- `VerificationStatus`: `verified`, `supported`, `disputed`, `unverified`,
  `rejected`.
- `PublicationStatus`: `draft`, `review`, `approved`, `rejected`.
- `RelationType`: `exact`, `synonym`, `related`, `narrower`, `broader`, `phrase`.
- `ConflictType`: `numericAssociation`, `terminology`, `provenance`, `other`.

## Flujo local

1. `DreamsCatalogLoader.loadFile` o `loadString` lee JSON.
2. `DreamsCatalog.fromJson` convierte los objetos a modelos.
3. `CatalogValidator.validate` comprueba la estructura e integridad implementada.
4. `PublishableCatalogGate.evaluate` ejecuta la validación editorial.
5. Solo un `PublishableCatalogResult` con catálogo debería llegar a la pantalla
   índice.
6. Búsqueda y descifrador operan de forma determinista y local.

## Presentación actual

La navegación de producción en `presentation/dreams_navigation.dart` crea
`DreamsNumbersHomePage` sin catálogo. Por tanto, el estado actual visible es
contenido no autorizado o en preparación. El fixture se encuentra únicamente en
`test/fixtures/dreams_numbers_fixture.json`.

## Limitaciones confirmadas

- Las pantallas Tabla, Diccionario y Descifrador aceptan `DreamsCatalog?`
  directamente. El tipo no obliga a pasar por `PublishableCatalogGate`.
- El cargador no ejecuta el archivo JSON Schema; replica parte de sus reglas con
  parsing Dart y `CatalogValidator`.
- No existe persistencia, migración de versiones ni catálogo real de producción.
- No existe una interfaz de repositorio que encapsule carga y autorización.
