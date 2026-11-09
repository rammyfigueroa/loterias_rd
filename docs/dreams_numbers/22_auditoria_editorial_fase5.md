# Auditoría editorial de la Fase 5.1

## Documentos 15-18

No se encontraron bajo otro nombre, en otra ruta ni en el historial Git local.
La carpeta `docs/` aparece sin seguimiento en el estado actual. Se reconstruyeron
los documentos 15-18 a partir del código y las pruebas existentes, sin atribuir
decisiones no implementadas.

## Estado técnico

El módulo tiene modelos separados, cargador local, validación estructural,
búsqueda determinista, descifrador local, frontera publicable y presentación con
estados vacíos. La navegación activa no carga catálogo. El fixture sintético no
está declarado como asset.

## Resultado del control editorial

Controles confirmados:

- Estados explícitos de derechos, verificación y publicación.
- Referencias de afirmaciones a fuentes y entradas.
- Referencias de conflictos a afirmaciones existentes.
- Rechazo de fuentes sin derechos autorizados o licencia abierta.
- Rechazo de afirmaciones no verificadas según la política actual.
- Rechazo de interpretaciones cuyo estado de publicación no sea aprobado.
- Catálogo global debe estar aprobado.
- Conflictos permanecen separados.
- Ruta activa sin contenido real ni fixture.

Hallazgos bloqueantes:

1. No se valida `verificationStatus` de una interpretación al publicar.
2. Tabla, Diccionario y Descifrador aceptan un catálogo crudo y pueden omitir el
   gate si una integración futura los instancia directamente.
3. Buscador y descifrador confían totalmente en la autorización previa.
4. JSON Schema no se ejecuta en runtime.
5. La aceptación de `supported` como publicable requiere decisión editorial.

No hay exposición actual confirmada porque la única navegación de producción
abre el módulo sin catálogo. No se recomienda conectar datos reales mientras los
hallazgos 1 y 2 permanezcan.

## Clasificación de las 15 fichas

La clasificación indica el bloqueo principal actual. Ninguna está autorizada.

| Ficha | Clasificación | Motivo documental |
|---|---|---|
| DP-001 Culebra | Requiere investigación adicional | Conflicto numérico y lexical; origen no verificado. |
| DP-002 Vaca | Requiere evaluación de derechos | Coincidencia local, pero fuentes S01/S04 sin autorización suficiente. |
| DP-003 Maco | Requiere investigación adicional | Dominicanismo respaldado; vínculo sueño-número solo local y sin tradición primaria. |
| DP-004 Agua | Requiere evaluación de derechos | Coincidencia editorial sin procedencia histórica demostrada. |
| DP-005 Lluvia | Requiere investigación adicional | Coincidencia principal con solapamiento interno en S01. |
| DP-006 Inundación | Requiere investigación adicional | Origen y alcance de “crecida” pendientes. |
| DP-007 Muerto | Requiere investigación adicional | Tres asociaciones incompatibles; contexto cultural no valida números. |
| DP-008 Muerto que habla | Requiere evaluación de derechos | Coincidencia entre publicaciones, origen histórico no demostrado. |
| DP-009 Bebé | Requiere investigación adicional | Conflicto, ambigüedad lexical y versiones sin fecha. |
| DP-010 Dinero | Requiere evaluación de derechos | Coincidencia editorial sin prueba de origen dominicano. |
| DP-011 Caballo | Requiere evaluación de derechos | Coincidencia local; historia, transmisión y permisos pendientes. |
| DP-012 Río | Requiere investigación adicional | Conflicto río/arroyo y agrupación semántica incompatible. |
| DP-013 Casa | Requiere investigación adicional | Sin asociación identificada; no debe generarse número. |
| DP-014 Gallina | Requiere investigación adicional | Asociación aislada y conflicto de casilla con fantasma. |
| DP-015 Árbol/mata | Requiere investigación adicional | Coincidencia parcial y granularidad lingüística no resuelta. |

Resultado agregado:

- Preparada para revisión sin otro bloqueo principal: **0**.
- Requiere investigación adicional: **10**.
- Requiere evaluación de derechos: **5**.
- Rechazada editorialmente: **0**.
- Autorizada para publicación: **0**.

“Preparada para revisión” describe el conjunto como artefacto de investigación,
pero no elimina los bloqueos específicos anteriores.

## Riesgos de derechos y representación

- Reproducir selección, estructura o redacción de S01-S05.
- Tratar coincidencias entre sitios como permiso o autenticidad dominicana.
- Adaptar material con restricciones NC/ND para una aplicación distribuida.
- Copiar definiciones lexicográficas o ejemplos sustanciales.
- Presentar relaciones semánticas como sinónimos.
- Convertir contenido cultural en recomendación de juego.

## Decisión

**AUDITORÍA COMPLETADA; CATÁLOGO NUMÉRICO NO APTO PARA PUBLICACIÓN.**
