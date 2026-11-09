# Cierre conservador del módulo

## Estado

El módulo Sueños y Números Dominicanos se conserva completo en el código, pero
su acceso público queda desactivado por defecto. La decisión responde a que no
existe todavía un catálogo numérico propio y autorizado, las fichas culturales
permanecen en revisión, la investigación de campo no ha comenzado y no se han
confirmado autorizaciones de terceros.

## Componentes conservados

- Pantalla índice y sus seis ramas.
- Tabla 00-99, diccionario y descifrador local.
- Tradiciones y Creencias, Variantes y Expresiones y Numerología Dominicana.
- Modelos, cargador, búsqueda, análisis, validadores y controles editoriales.
- Esquema JSON 1.2.0, catálogo de revisión, fixtures y pruebas.
- Documentación de las fases anteriores.

## Acceso público

Con la bandera desactivada:

- La tarjeta principal no se construye ni reserva espacio.
- La entrada del menú lateral no se construye.
- La función pública de navegación no abre la pantalla del módulo.

Con la bandera activada explícitamente, las entradas y la navegación existentes
se conservan sin alterar la estructura de las seis ramas.

## Límite editorial

La bandera de visibilidad no autoriza contenido. `PublishableCatalogGate`,
`PublishableDreamsCatalog`, `RightsEvidence` y las restricciones del esquema
continúan siendo requisitos independientes. El catálogo de revisión no forma
parte de los assets declarados en `pubspec.yaml`; los fixtures permanecen bajo
`test/`.

## Decisión de cierre

No publicar ni desplegar el módulo en esta etapa. Conservar el trabajo para una
actualización futura después de completar revisión cultural, documental,
jurídica y editorial.
