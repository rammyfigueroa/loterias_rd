# Fase 9.3 - Estadisticas claras y confiables

## Cambios

- La pantalla local distingue sorteos analizados de apariciones observadas.
- Se muestra el periodo aplicado y la cobertura real disponible para la loteria seleccionada.
- Los rangos personalizados solo se aplican al pulsar `Aplicar fechas`.
- Un rango pendiente no reutiliza estadisticas del filtro anterior.
- Se aclara que el resumen es historico y no predice resultados futuros.
- El acceso a Coincidencias de Primera identifica correctamente las dos series disponibles.

## Validaciones

El validador compartido rechaza antes de calcular o consultar:

- Desde posterior a Hasta.
- Fechas futuras, usando la fecha calendario dominicana en la pantalla local.
- Rangos fuera de la cobertura informada.
- Rangos con una fecha faltante.

Los selectores de calendario no permiten fechas inexistentes. El parser existente tambien verifica estrictamente el dia, mes y anio. Las fechas de resultados se normalizan de forma consistente para evitar diferencias entre medianoche local y la fecha dominicana.

## Tamano de muestra y cobertura

- `Sorteos analizados` cuenta registros de sorteos incluidos por los filtros.
- `Apariciones` cuenta numeros validos observados en esos sorteos.
- La cobertura muestra la primera y ultima fecha verificable de los resultados disponibles para la seleccion.
- Los datos no parseables se excluyen de calculos con periodo, sin inventar fechas.

## Estados

- La primera carga conserva su indicador dedicado.
- Una actualizacion mantiene las estadisticas anteriores visibles.
- Un error de actualizacion conserva la muestra anterior, informa la limitacion y permite reintentar.
- Un periodo sin resultados muestra una muestra de cero y un estado vacio.
- Cambiar a un rango no aplicado limpia los resultados visibles del periodo anterior.

## Pruebas

Las pruebas locales cubren rango valido, invertido, futuro, fuera de cobertura, incompleto, fechas inexistentes, ausencia de consultas invalidas, tamano de muestra, cobertura, estado vacio, error, reintento, datos anteriores, respuestas tardias existentes y lenguaje no predictivo.

## Limitaciones

- La cobertura local se deriva exclusivamente de las fechas parseables recibidas en `/results`.
- No se modificaron formulas, endpoints, Worker, D1, dependencias ni modulos experimentales.
