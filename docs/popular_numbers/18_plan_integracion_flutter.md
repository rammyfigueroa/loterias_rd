# Plan de integración Flutter

## Ubicación

Añadir en una fase futura una entrada “Relaciones históricas” dentro de la
pantalla Estadísticas. No integrarla en Sueños y Números ni depender de su
feature flag: el origen es histórico y estadístico, no cultural.

## Reutilización

- `StatisticsDrawOption` para operador y sorteo.
- `StatisticsDateRange` y formato ISO.
- controles visuales `Desde`, `Hasta`, `Todo el historial`, `Aplicar fechas`;
- patrones repository/remote source/controller;
- estados loading, vacío, error y reintento;
- IDs de solicitud para descartar respuestas tardías;
- colores, tarjetas y restricciones responsive de Estadísticas.

## Componentes propuestos

1. Encabezado y descargo estadístico.
2. Selector segmentado de serie con una sola opción activa.
3. Selector de número origen `00-99`, preferiblemente cuadrícula o menú con
   búsqueda, no campo libre sin validación.
4. Período de análisis existente.
5. Resumen: apariciones del origen, transiciones válidas, cobertura y rango.
6. Tabla ordenada: número siguiente, veces, frecuencia observada y última fecha.
7. Estado de cobertura y advertencias visibles.

No mostrar modo “Ambas”, sugerencias de jugada, insignias de “fuerte” ni un
número “recomendado”.

## Modelos futuros

- `NumberTransitionQuery`;
- `NumberTransitionQuality`;
- `NumberTransitionRow`;
- `NumberTransitionsResponse`;
- `NumberTransitionsRepository`;
- `NumberTransitionsController`.

Mantenerlos separados de `first_prize_statistics.dart` si el archivo deja de
tener una sola responsabilidad. La configuración de series sí puede ser común.

## Estado del controlador

El controlador debe mantener `selectedDraw`, `originNumber`, rango pendiente y
aplicado, cobertura, estado de carga, error y respuesta. Cada cambio incrementa
un `requestId`, limpia datos y realiza una consulta nueva. Solo una respuesta con
el ID y filtros vigentes puede actualizar la vista.

La caché de repository incluirá todos los filtros. Debe existir una política de
invalidación o expiración; no asumir que el resultado histórico nunca cambia.

## Presentación

- Mostrar porcentaje con uno o dos decimales, pero conservar conteo y tamaño de
  muestra al lado.
- Fecha visible en `DD/MM/AAAA` y datos enviados como ISO.
- Para `T(a)=0`, explicar “No hay una transición verificable dentro de este
  período”, no “Nunca sale después”.
- Para cobertura incompleta, indicar cuántas transiciones fueron excluidas.
- Mantener controles accesibles y dimensiones estables en móvil.

## Secuencia de implementación recomendada

1. Motor puro y tests del Worker.
2. Contrato y tests de ruta.
3. Validación de consulta D1 y caché.
4. Modelos y remote source Dart.
5. Repository y controlador con respuestas tardías.
6. UI y pruebas responsive/accesibilidad.
7. Pruebas completas sin despliegue.
