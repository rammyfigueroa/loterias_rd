# Plan para un primer catálogo publicable

## Objetivo conservador

Preparar un catálogo pequeño cuya procedencia, derechos, redacción y aprobación
puedan verificarse por registro. No convertir automáticamente las 15 fichas ni
usar coincidencias entre fuentes como autorización.

## Capas propuestas

### 1. Información histórica documentada

Priorizar una síntesis original sobre la relación histórica entre sueños,
creencias y números, basada en fuentes académicas o culturales como S06-S10.
Usar citas breves, referencias bibliográficas y revisión de derechos. Separar
hechos históricos de creencias reportadas.

### 2. Vocabulario dominicano

Incluir únicamente términos cuyo uso dominicano pueda verificarse con fuentes
lexicográficas adecuadas. Redactar definiciones originales y conservar matices
entre sinónimo, variante, concepto relacionado y frase. No copiar entradas ni
ejemplos protegidos.

### 3. Asociaciones numéricas

Mantener esta capa vacía en la primera revisión salvo que cada asociación tenga:

- Fuente identificada y ubicación precisa.
- Derechos `authorized` u `openLicense` compatibles con el uso real.
- Verificación editorial definida.
- Trazabilidad de versión y fecha.
- Conflictos conservados, no resueltos por mayoría.
- Revisión jurídica cuando se derive de una tabla o selección comercial.

### 4. Interpretaciones originales

Crear solo después de aprobar fuentes y afirmaciones. Deben distinguirse de las
afirmaciones documentales, evitar predicciones y recomendaciones de juego, y
tener verificación y publicación aprobadas por personas distintas cuando sea
posible.

### 5. Información pendiente

Conservar fuera del catálogo distribuido: permisos sin respuesta, versiones sin
fecha, atribuciones regionales no demostradas, conflictos no investigados,
material NC/ND dudoso y las 15 fichas piloto mientras sigan bloqueadas.

## Alternativas de permisos

1. Solicitar autorización escrita a titulares aparentes de S01-S05, definiendo
   obra exacta, extracción, adaptación, offline, uso comercial, territorio,
   duración y atribución.
2. Pedir a instituciones culturales acceso y términos de reutilización para
   fondos S06-S10, S11 y S14.
3. Negociar una licencia específica o recibir un conjunto de datos autorizado
   directamente del titular.
4. Encargar investigación original con protocolo de consentimiento para fuentes
   orales futuras; no recopilar testimonios antes de aprobar privacidad.
5. Excluir toda asociación comercial y publicar inicialmente solo una biblioteca
   histórica con derechos claros.

Una respuesta debe verificarse como proveniente de quien puede conceder los
derechos. La presencia del mismo dato en varias fuentes no sustituye permiso.

## Criterios de entrada a revisión

- Corregir las dos brechas bloqueantes del control editorial.
- Definir si `supported` es suficiente para publicación o solo para revisión.
- Aplicar el JSON Schema o documentar formalmente la equivalencia del validador.
- Añadir prueba positiva de un catálogo mínimo totalmente aprobado.
- Añadir pruebas negativas para interpretación no verificada y bypass del gate.
- Registrar responsable, fecha y evidencia de cada aprobación.
- Revisar el subconjunto con especialista dominicano y asesoría jurídica.

## Propuesta de Fase 5.2

Realizar primero un endurecimiento técnico y una decisión editorial, sin cargar
contenido real:

1. Hacer imposible que presentación reciba `DreamsCatalog` sin autorización.
2. Validar `EditorialInterpretation.verificationStatus`.
3. Resolver la política de `supported`.
4. Agregar pruebas de seguridad de extremo a extremo.
5. Seleccionar un piloto histórico sin asociaciones numéricas comerciales.
6. Solicitar permisos solo con autorización expresa del usuario para contactar.

Hasta completar esos puntos, mantener todas las fichas fuera de assets y no
recomendar publicación del módulo con datos reales.
