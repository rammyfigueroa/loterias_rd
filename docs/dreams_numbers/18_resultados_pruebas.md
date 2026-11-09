# Resultados de pruebas de Sueños y Números

## Cobertura específica de la Fase 5.2

Las pruebas negativas verifican rechazo de:

- Interpretación aprobada con `supported`, `disputed`, `unverified` o `rejected`.
- Interpretación sin fuentes o con referencia inexistente.
- Fuente no verificada.
- Derechos `openLicense`, `permissionPending`, `unauthorized`, `restricted` y
  `unknown` sin autorización explícita para el uso previsto.
- Afirmación documental `supported`.
- JSON con campos desconocidos.
- Referencias inexistentes, IDs duplicados, número inválido y versión incompatible.
- Fixture sintético intentando atravesar el gate.
- Referencia directa a `DreamsCatalog` desde presentación.

Las pruebas positivas construyen una variante sintética totalmente aprobada y
verifican:

- Paso correcto por `PublishableCatalogGate`.
- Recepción del tipo seguro por Tabla, Diccionario y Descifrador.
- Búsqueda y análisis local.
- Conservación de fuentes y conflictos.
- Inmutabilidad de colecciones y listas anidadas.
- Estados vacíos sin catálogo.

## Comandos de validación

```text
flutter test test/dreams_numbers_catalog_test.dart test/dreams_numbers_presentation_test.dart
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
dart analyze lib/features/dreams_numbers test/dreams_numbers_catalog_test.dart test/dreams_numbers_presentation_test.dart
jq empty ../docs/dreams_numbers/dreams_catalog.schema.json
git diff --check
```

Los resultados finales de regresión se registran en
`24_seguridad_editorial_fase5_2.md`.

## Limitaciones

- No se ejecutan builds de distribución.
- No hay despliegue ni publicación.
- Los fixtures son exclusivamente sintéticos y permanecen bajo `test/`.
- No existe catálogo real para una validación jurídica o editorial de extremo a
  extremo.
