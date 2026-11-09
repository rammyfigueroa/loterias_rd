# Ampliación de RightsEvidence

## Versión 1.2

El esquema 1.2 agrega `legalBasisType` sin eliminar los campos 1.1. Los
catálogos 1.0 y 1.1 continúan siendo legibles, pero `PublishableCatalogGate`
exige 1.2 para publicar. No existe migración automática ni elevación de estados.

Bases jurídicas documentales:

- `explicitPermission`: permiso escrito o contrato.
- `originalWork`: titularidad editorial sobre texto original.
- `compatibleOpenLicense`: licencia abierta cuyas condiciones fueron evaluadas.
- `reviewedLegalException`: excepción concreta respaldada por revisión jurídica.

## Requisitos comunes

Se mantienen titular, referencia de evidencia, fechas, alcance, territorio, uso
comercial, redistribución, derivados, atribución, restricciones y revisión. La
evidencia debe estar vigente y cubrir el contenido exacto.

## Reglas por base

### explicitPermission

Requiere `writtenPermission` o `contract`, documento identificable, titular,
alcance, vigencia y facultades compatibles. No cubre material fuera de sus
`scopeReferences`.

### originalWork

Requiere `authorshipReference`, `originalityDeclaration`,
`editorialReviewReference`, `historicalFactReferences` y confirmación explícita
de ausencia de reproducción no autorizada. Solo puede cubrir `article` o
`editorialText`; nunca tablas, claims, imágenes ni datos estructurados.

Una fuente usada únicamente para documentar hechos puede permanecer
`permissionPending`, siempre que esté verificada y no tenga derechos
`unknown`, `unauthorized` o `restricted`. Esto no autoriza la fuente: la
evidencia cubre solo la obra original identificada.

### compatibleOpenLicense

Requiere identificador, versión, URL, condiciones y referencia de atribución.
Además debe permitir el uso comercial, redistribución, derivados y territorio
exigidos por el `PublicationContext`.

### reviewedLegalException

Requiere jurisdicción, excepción concreta, referencia de revisión jurídica,
rol del revisor, fecha de conclusión y limitaciones. No se infiere a partir de
una cita breve ni de disponibilidad pública.

## Campos incorporados

`legalBasisType`, `authorshipReference`, `originalityDeclaration`,
`editorialReviewReference`, `historicalFactReferences`,
`unauthorizedReproductionConfirmedAbsent`, `licenseIdentifier`,
`licenseVersion`, `licenseUrl`, `licenseConditions`, `attributionReference`,
`legalJurisdiction`, `legalException`, `legalReviewReference`,
`legalReviewerRole`, `legalConclusionDate` y `legalLimitations`.

Las listas nuevas se copian de forma inmutable dentro de
`PublishableDreamsCatalog`.
