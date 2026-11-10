# Plan de datos históricos reales

Fecha: 2026-11-09.

## Inventario confirmado

### Staging

- un operador estructurado: Nacional;
- dos sorteos estructurados: Gana Más y Lotería Nacional;
- 16 resultados sintéticos;
- 19 registros sintéticos de cobertura;
- 1 revisión sintética;
- cero datos reales o personales.

### Producción

El Worker público `api` entrega resultados actuales, pero la última auditoría
confirmó que no tenía binding D1 histórico. No se identificó una D1 de
producción ni un historial persistente compatible con transiciones.

Por tanto, **no hay un conjunto histórico real aprobado y disponible para esta
función**. La cantidad de resultados actuales observada en otras fases no prueba
cobertura histórica, continuidad por serie ni derechos para backfill.

## Esquema disponible

Las migraciones locales permiten almacenar:

- operadores y sorteos con IDs exactos;
- resultados de primera posición;
- fecha e identidad del proveedor;
- fuente, checksum, payload y actualización;
- cobertura diaria y evidencia de no sorteo;
- revisiones;
- estado de backfill.

El esquema es técnicamente apto, pero su existencia no autoriza una fuente ni
demuestra completitud.

## Investigación requerida

Por cada serie candidata:

1. identificar proveedor y términos aplicables;
2. confirmar licencia para uso, almacenamiento y redistribución en una app;
3. verificar ID de operador, ID de sorteo y campo de primera posición;
4. determinar primera y última fecha comprobable;
5. registrar frecuencia esperada y excepciones de calendario;
6. medir resultados, cobertura, huecos, duplicados y conflictos;
7. conservar fuente, timestamps, checksum y revisión;
8. separar ausencia de resultado, fallo de consulta y no sorteo verificado;
9. obtener revisión jurídica/editorial cuando corresponda;
10. aprobar explícitamente la D1 de destino antes de escribir.

## Criterios de aceptación

- procedencia y derechos documentados;
- serie identificada sin coincidencias parciales de texto;
- cobertura cuantificada por fecha;
- conflictos resueltos o excluidos con trazabilidad;
- backfill reproducible e idempotente;
- revisiones verificadas;
- ninguna mezcla entre series;
- pruebas estadísticas sobre snapshot inmóvil;
- fixture sintético excluido del entorno real;
- revisión humana antes de habilitar API pública.

## Fases propuestas

1. auditoría legal y técnica de fuente;
2. inventario de serie sin escritura;
3. backfill local o en entorno aislado autorizado;
4. informe de cobertura y calidad;
5. aprobación de D1 real dedicada;
6. carga controlada y verificación;
7. endpoint privado de validación;
8. aprobación de exposición pública.

No se debe copiar D1 staging ni convertir fixtures en producción. Tampoco debe
ejecutarse el backfill existente contra un proveedor hasta recibir autorización
específica sobre fuente, destino y alcance.
