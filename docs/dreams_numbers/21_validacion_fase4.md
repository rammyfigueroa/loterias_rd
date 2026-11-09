# Validacion de la Fase 4

## Cobertura automatizada

Las pruebas de presentacion cubren:

- Apertura desde la tarjeta principal.
- Apertura desde el menu lateral mediante la misma ruta.
- Acceso visible a las seis ramas y regreso.
- Pantalla estrecha de 320 dp con texto al 180 %.
- Los seis estados de interfaz.
- Cuadricula con 00 y 99 y seleccion de numeros.
- Diccionario sin catalogo autorizado.
- Descifrador con texto vacio y simbolos sin catalogo.
- Ausencia de numeros de fixtures en la presentacion.
- Rechazo del fixture sintetico en la frontera editorial.
- Ausencia de fixtures entre los assets de produccion.

Las pruebas existentes de la aplicacion continúan cubriendo resultados,
estadisticas, favoritos, metadatos y componentes de inicio.

## Comandos

```text
flutter test test/dreams_numbers_presentation_test.dart
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
jq empty ../docs/dreams_numbers/dreams_catalog.schema.json
git diff --check
```

## Criterios pendientes

- No se ejecuto un build de distribucion, conforme a la restriccion de la fase.
- No se realizo validacion visual en un dispositivo fisico.
- Contraste y semantica se verificaron mediante estilos y pruebas de widgets; una
  auditoria instrumental completa queda pendiente.
- Los documentos 15 a 18 no estaban disponibles.
- No puede probarse contenido real disponible hasta recibir un catalogo con
  permisos, fuentes verificadas y aprobacion editorial.
