# Fase 4: integracion visual

## Alcance

La integracion agrega el modulo **Suenos y Numeros Dominicanos** a la aplicacion
Flutter sin modificar el backend, endpoints, configuracion nativa ni dependencias.
La pantalla de inicio incorpora una tarjeta despues de Loterias y antes de
Resultados recientes. El menu lateral incluye un segundo acceso al mismo flujo.

## Navegacion

Ambos accesos llaman `openDreamsNumbersModule`, que abre una unica instancia de
`DreamsNumbersHomePage`. La pantalla indice presenta seis ramas:

1. Tabla Dominicana de Suenos.
2. Diccionario de Suenos.
3. Descifrador de Suenos.
4. Tradiciones y Creencias.
5. Variantes y Expresiones.
6. Numerologia Dominicana.

Cada rama utiliza navegacion local con `MaterialPageRoute` y conserva el regreso
normal de Flutter.

## Arquitectura de presentacion

- `application/publishable_catalog.dart`: frontera editorial previa a la UI.
- `presentation/dreams_numbers_home_page.dart`: indice de las seis ramas.
- `presentation/dream_table_page.dart`: selector local de 00 a 99.
- `presentation/dream_dictionary_page.dart`: busqueda determinista y categorias.
- `presentation/dream_decoder_page.dart`: adaptador visual del analizador local.
- `presentation/dreams_placeholder_pages.dart`: bibliotecas futuras seguras.
- `presentation/widgets/`: tarjeta de entrada, menu, estados y aviso cultural.

No se duplica el buscador ni el descifrador de la Fase 3. La UI recibe un
`DreamsCatalog` solamente despues de superar `PublishableCatalogGate`.

## Contenido actual

No existe un catalogo de produccion autorizado. Por ello, la navegacion de la
aplicacion crea el modulo con `PublishableCatalogResult.unavailable()`. Los
fixtures permanecen en `test/fixtures` y nunca se cargan desde produccion.

## Limitaciones documentales

Durante la auditoria no se encontraron los documentos 15, 16, 17 y 18
solicitados por la Fase 4. La implementacion se baso en los documentos 01 a 14,
el esquema 1.0.0 y el codigo validado de la Fase 3. Esta ausencia debe resolverse
antes de autorizar contenido editorial real.
