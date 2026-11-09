# Seguridad editorial de la Fase 5.2

## Riesgos originales

La Fase 5.1 confirmó dos rutas bloqueantes:

1. Una interpretación `approved` podía superar la publicación aunque su
   `verificationStatus` no fuera `verified`.
2. Las pantallas aceptaban `DreamsCatalog` directamente, por lo que un llamador
   futuro podía omitir `PublishableCatalogGate`.

También existía una diferencia entre `additionalProperties: false` del esquema y
la carga Dart, que ignoraba propiedades desconocidas.

## Soluciones aplicadas

- Política de publicación limitada a `verified`, `approved` y derechos
  `authorized`.
- Validación de estado y fuentes en cada interpretación.
- Rechazo de interpretaciones sin referencias.
- Rechazo de propiedades JSON no declaradas.
- Fechas alineadas con `date` y `date-time` del esquema.
- Creación controlada de `PublishableDreamsCatalog` dentro del gate.
- Copia profunda y listas no modificables.
- Presentación tipada exclusivamente con el catálogo seguro.
- Búsqueda y análisis de producción expuestos como métodos del tipo seguro.

## Política de derechos

Solo `RightsStatus.authorized` se acepta automáticamente. `openLicense` queda
rechazado porque el modelo no diferencia licencias comerciales de licencias NC,
ND u otras condiciones incompatibles. Una futura ampliación debe registrar
licencia, alcance, versión, evidencia y compatibilidad con el uso previsto antes
de flexibilizar esta regla.

## Pruebas

Las pruebas específicas incluyen casos negativos para todos los estados de
verificación no aceptados, derechos insuficientes, fuentes ausentes/no verificadas,
estructura inválida y bypass de presentación. El caso positivo usa solamente una
copia sintética preparada dentro del test.

Se comprueba que los conflictos no se fusionan, que las fuentes llegan con cada
asociación y que las colecciones del catálogo seguro no pueden modificarse.

## Resultados de regresión

- Suite Flutter completa: **100 pruebas aprobadas, 0 fallidas**.
- Análisis aislado del módulo y sus pruebas: **sin problemas**.
- Análisis global: **53 avisos preexistentes**, sin nuevas incidencias del módulo.
- Esquema JSON: sintaxis válida con `jq empty`.
- `git diff --check`: correcto.
- No se ejecutaron builds, despliegues ni publicaciones.

## Riesgos residuales

- `authorized` sigue siendo una etiqueta, no una evidencia jurídica almacenada.
- No existe un modelo de alcance de licencia comercial, territorio o caducidad.
- No se ejecuta un motor JSON Schema; las reglas equivalentes se mantienen en
  Dart y requieren sincronización.
- El dominio crudo permanece accesible a código interno, aunque la presentación
  ya no puede recibirlo por tipos.
- No existe contenido real autorizado para validar el flujo completo.

## Decisión

La frontera técnica queda fortalecida para continuar desarrollo, pero no autoriza
las 15 fichas piloto ni permite recomendar publicación de contenido real. La
Fase 5.3 debe diseñar evidencia de permisos y un catálogo histórico mínimo, sin
asociaciones comerciales, antes de cualquier activación editorial.
