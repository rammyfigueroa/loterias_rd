# Estados de interfaz de Suenos y Numeros

## Estados soportados

`DreamsContentState` define seis estados explicitos:

- `available`: contenido validado y autorizado.
- `noAuthorizedContent`: existen datos o contexto, pero no pueden publicarse.
- `preparing`: seccion preparada y pendiente de investigacion o autorizacion.
- `loadError`: fallo al cargar un catalogo autorizado.
- `noResults`: consulta valida sin coincidencias documentales.
- `unverifiable`: informacion que no supera los controles de verificacion.

`DreamsContentStateView` ofrece titulo, explicacion, icono semantico y una accion
opcional de reintento. De esta forma ninguna rama queda completamente vacia.

## Reglas editoriales

1. La UI no decide si un catalogo es publicable.
2. `PublishableCatalogGate` ejecuta `CatalogValidator.validateForPublication`.
3. Si existe cualquier problema, el resultado no contiene un catalogo.
4. Fuentes sin derechos o sin verificacion bloquean las afirmaciones asociadas.
5. Interpretaciones no aprobadas bloquean el catalogo.
6. Los conflictos se conservan como afirmaciones independientes.
7. El descifrador no analiza contenido cuando el catalogo no esta autorizado.
8. Los relatos se procesan localmente y no se guardan ni se envian a servidores.

## Estado inicial de las ramas

- Tabla: selector 00-99 disponible; asociaciones no autorizadas ocultas en la
  frontera de datos.
- Diccionario: categorias previstas identificadas y contenido en preparacion.
- Descifrador: formulario disponible; no produce numeros sin catalogo aprobado.
- Tradiciones, Variantes y Numerologia: contenido en preparacion.

El aviso cultural se muestra en el indice y en las pantallas que pueden presentar
asociaciones: las tradiciones populares no son predicciones ni garantias.
