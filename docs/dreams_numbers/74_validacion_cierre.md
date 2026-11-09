# Validación del cierre conservador

## Línea base

- `flutter test`: 131/131 pruebas aprobadas antes del cambio.
- `flutter analyze`: 53 avisos preexistentes, sin errores.
- Los avisos corresponden principalmente a APIs deprecadas y elementos no
  usados en pantallas ajenas a este cambio.

## Pruebas añadidas

- La bandera central está desactivada por defecto.
- La tarjeta y la entrada del menú se ocultan con la bandera desactivada.
- La navegación no abre el módulo con la bandera desactivada.
- Las pruebas existentes activan explícitamente el módulo y conservan acceso a
  las seis ramas.

## Controles editoriales verificados

- Esquema declarado: 1.2.0.
- Catálogo de revisión: cero entradas, cero asociaciones y cuatro artículos en
  estado editorial `review`.
- El catálogo de revisión no aparece en los assets de producción.
- Los fixtures sintéticos permanecen en `test/fixtures`.
- La presentación utiliza `PublishableDreamsCatalog`, no un catálogo bruto.
- `PublishableCatalogGate` y la validación de `RightsEvidence` permanecen en el
  código y sus pruebas no fueron eliminadas.

## Validaciones finales

- `flutter test`: 134/134 pruebas aprobadas.
- Pruebas nuevas: 3; pruebas previas conservadas: 131.
- `flutter analyze`: los mismos 53 avisos preexistentes y ningún aviso nuevo en
  los archivos modificados para la bandera.
- `git diff --check`: aprobado.
- Sintaxis del esquema y catálogo JSON: válida.
- Catálogo de revisión: cero entradas y cero asociaciones.

No se generarán builds de distribución ni se realizará despliegue.
