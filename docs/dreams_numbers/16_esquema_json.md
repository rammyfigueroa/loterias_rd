# Esquema JSON implementado

## Identificación

El contrato documental está en `docs/dreams_numbers/dreams_catalog.schema.json`.
Declara JSON Schema Draft 2020-12 y versión fija `1.0.0` mediante
`metadata.schemaVersion`.

La raíz exige:

- `metadata`
- `sources`
- `entries`
- `claims`
- `interpretations`
- `conflictGroups`

La raíz y cada objeto declarado usan `additionalProperties: false`.

## Reglas declaradas

- IDs: `^[a-z][a-z0-9_-]*$`.
- Números: cadenas de dos dígitos entre `00` y `99`.
- Fechas de fuente: formato `date`.
- Fecha de generación: formato `date-time`.
- Estados y relaciones: enums cerrados equivalentes a los modelos Dart.
- `claimIds` en conflictos: mínimo dos y sin duplicados.
- `sourceReferences` en interpretaciones: sin duplicados.
- Referencias: se representan como IDs, aunque JSON Schema no verifica por sí
  solo que el objeto referenciado exista.

## Separación de contenido

El esquema separa:

1. Procedencia y derechos en `sources`.
2. Vocabulario y variantes en `entries`.
3. Asociaciones numéricas documentales en `claims`.
4. Texto editorial en `interpretations`.
5. Contradicciones explícitas en `conflictGroups`.
6. Estado global en `metadata`.

No existe un campo numérico único dentro de `CatalogEntry`; varias afirmaciones
pueden conservar números distintos y fuentes distintas.

## Relación con el runtime

`DreamsCatalogLoader` utiliza `dart:convert`, los factories `fromJson` y
`CatalogValidator`. No carga ni ejecuta `dreams_catalog.schema.json`. Por tanto:

- El esquema sirve como contrato y documentación verificable externamente.
- `jq empty` solo confirma que el archivo JSON del esquema es sintácticamente
  válido.
- Las garantías efectivas en la app son las implementadas en Dart.
- `additionalProperties: false`, `format` y algunas restricciones del esquema no
  se aplican automáticamente durante la carga si no están replicadas en Dart.

## Fixture

`test/fixtures/dreams_numbers_fixture.json` usa versión `1.0.0`, locale de prueba
y términos `simbolo_prueba_*`. Es deliberadamente `draft` y contiene una fuente
con permiso pendiente, por lo que no supera la validación de publicación.
