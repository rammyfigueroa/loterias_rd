# Validación de la Fase 8.1

Fecha: 2026-11-09.

## Auditoría realizada

- Migración D1 y sus índices.
- Repositorio de historial, revisiones y cobertura.
- Identificación estricta de series.
- Motor, servicio, rutas, paginación y caché estadística.
- Validación de fechas y zona `America/Santo_Domingo`.
- Modelos, remote source, repository, controlador y pantalla Flutter.
- Pruebas existentes de historial, estadísticas, rangos y respuestas tardías.

## Decisiones verificables

- La unidad es un par de eventos adyacentes de una sola serie.
- Ambos eventos deben estar dentro del rango inclusivo.
- La primera versión usa solo primera posición.
- La cobertura por defecto es verificada y conservadora.
- La frecuencia relativa usa únicamente transiciones válidas del origen como
  denominador.
- El endpoint propuesto conserva el prefijo `/statistics`.
- No se mezclan series ni se usan asociaciones populares.

## Evaluación D1

La tabla y los índices actuales son suficientes para un primer motor en memoria
con el volumen histórico previsto. `idx_first_prize_draw_date` soporta lectura
cronológica por serie y `idx_first_prize_number_date` ayuda a localizar
apariciones. No se justifica migración antes de medir el plan y latencia reales.

Para mayor escala, evaluar `LEAD()` sobre la secuencia filtrada o materialización
solo con evidencia de rendimiento. Cualquier índice adicional debe basarse en
`EXPLAIN QUERY PLAN`, volumen y costo medidos.

## Validaciones de fase

- [x] Seis documentos creados.
- [x] Especificación, API, modelo, pruebas e integración coherentes.
- [x] Ejemplos identificados como sintéticos.
- [x] Sin tablas comerciales ni lenguaje predictivo.
- [x] Sin cambios en Flutter, Worker, D1, migraciones o configuración.
- [x] Sin build, despliegue, commit o push.
- [x] Feature flag existente permanece desactivada.

## Riesgos pendientes

- Definir política de capacidad/TTL para caché antes de implementar.
- Medir costo de cargar el rango completo en Worker.
- Confirmar cobertura y licencia del historial usado.
- Decidir si la API normaliza `0` a `00` o exige dos dígitos; mantener una sola
  conducta en API y Flutter.
- Revisar texto de juego responsable y obligaciones vigentes antes de publicar.

## Recomendación para Fase 8.2

Implementar primero el motor puro y pruebas sintéticas, seguido del endpoint en
desarrollo local. No modificar producción ni Flutter hasta validar aislamiento,
cobertura, rangos, correcciones, rendimiento y contrato.

**FASE 8.1 ESPECIFICADA — LISTA PARA REVISIÓN TÉCNICA, NO PARA IMPLEMENTACIÓN AUTOMÁTICA**
