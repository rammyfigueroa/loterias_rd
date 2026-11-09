# Feature flag de Sueños y Números

## Definición

La fuente central es:

`loterias_rd_app/lib/app/app_features.dart`

```dart
abstract final class AppFeatures {
  static const bool dreamsNumbersEnabled = false;
}
```

El valor de producción es constante, local y desactivado por defecto. No utiliza
dependencias, servicios externos ni almacenamiento remoto.

## Puntos protegidos

- `ResultsPage` recibe el valor predeterminado central y omite la tarjeta.
- `_HomeDrawer` omite la entrada del menú lateral.
- `DreamsModulePromoCard` y `DreamsDrawerTile` también se ocultan por defecto.
- `openDreamsNumbersModule` devuelve sin navegar cuando la bandera está apagada.

La aplicación no declara rutas nombradas para este módulo. Sus accesos normales
convergen en la función de navegación protegida.

## Uso en pruebas

Las pruebas pueden pasar `enabled: true` a los widgets y a
`openDreamsNumbersModule`. `ResultsPage` también permite inyectar
`dreamsNumbersEnabled: true` para validaciones de integración. Esto no cambia el
valor predeterminado de producción.

## Procedimiento futuro de activación

1. Completar y documentar la aprobación editorial y jurídica del catálogo.
2. Confirmar que el contenido pasa `PublishableCatalogGate` sin excepciones.
3. Verificar que ningún fixture o catálogo de revisión esté en assets.
4. Cambiar únicamente `AppFeatures.dreamsNumbersEnabled` a `true`.
5. Ejecutar pruebas, análisis, validación JSON y revisión responsive.
6. Revisar manualmente tarjeta, menú, navegación y las seis ramas.
7. Preparar una versión nueva mediante el proceso normal de publicación.

Activar la bandera sin completar los controles editoriales no autoriza la
publicación.
