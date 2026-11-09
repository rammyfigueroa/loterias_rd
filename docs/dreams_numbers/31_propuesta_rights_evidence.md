# Propuesta de evolución de RightsEvidence

## Evaluación del modelo 1.1

El modelo actual representa bien permisos escritos, contratos, licencias
abiertas, dominio público y otra autorización, con alcance, vigencia, territorio
y facultades. Sin embargo, el gate exige evidencia asociada a cada fuente y
contenido, lo que no distingue adecuadamente entre autorización de terceros y
titularidad de una redacción original basada solo en hechos.

También faltan campos para registrar una excepción jurídica revisada, la obra
propia y una evaluación concreta de cita breve. Esto puede producir dos errores:
exigir permiso de terceros para toda síntesis factual original o, al intentar
evitarlo, sobreautorizar una paráfrasis demasiado cercana.

## Ampliación mínima propuesta, no implementada

Agregar un tipo de base jurídica separado de `authorizationType`:

- `thirdPartyPermission`: autorización otorgada por titular competente.
- `originalOwnership`: titularidad de Sorteos Dominicanos sobre texto original.
- `compatibleOpenLicense`: licencia identificada y revisada para el uso.
- `publicDomain`: determinación documentada de dominio público.
- `legalExceptionReviewed`: cita u otra excepción validada jurídicamente.

Campos propuestos:

- `legalBasisType`.
- `originalAuthor` y `commissionOrAssignmentReference` cuando corresponda.
- `underlyingFactReferences` para separar hechos de expresión reutilizada.
- `quotedTextReference`, `quotedExtent` y `quotationPurpose` para citas.
- `licenseIdentifier`, `licenseVersion` y `licenseUrl`.
- `legalReviewReference`, `legalReviewerRole` y `legalConclusionDate`.
- `adaptationAssessment` para paráfrasis, traducción o transformación.

## Reglas propuestas

1. `originalOwnership` cubre solo el texto original identificado; nunca habilita
   tablas, imágenes o redacción de las fuentes.
2. Los hechos deben tener trazabilidad documental, pero la evidencia de la obra
   propia debe permanecer separada de los permisos del material subyacente.
3. `compatibleOpenLicense` exige revisar versión, atribución, comercialidad,
   derivados, territorio y material excluido.
4. `legalExceptionReviewed` nunca se infiere automáticamente y requiere una
   referencia de revisión jurídica.
5. Una cita breve cubre solo el fragmento registrado.

No se recomienda cambiar la política del gate hasta aprobar esta propuesta y
añadir pruebas negativas específicas.
