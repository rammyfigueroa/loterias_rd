# Rendimiento local

Fecha: 2026-11-09.

## Entorno y método

Se ejecutó una medición local con D1 efímera mediante Wrangler 4.155.0. El
fixture sintético contenía 5,000 resultados diarios y 5,000 filas de cobertura,
desde 2012-01-01 hasta 2025-09-08. No se consultó producción.

Se midió por separado:

1. lectura cronológica parametrizada de resultados y cobertura;
2. adaptación y cálculo del motor;
3. diferencia aproximada de heap de Node durante lectura/cálculo.

## Resultado observado

| Métrica | Resultado |
| --- | ---: |
| Eventos | 5,000 |
| Filas de cobertura | 5,000 |
| Consulta D1 | 68.25 ms |
| Cálculo del motor | 29.21 ms |
| Incremento aproximado de heap | 3.56 MiB |
| Transiciones del origen sintético | 50 |
| Destinos distintos | 1 |

Es una medición puntual de desarrollo, no un SLA ni una predicción de latencia
en Cloudflare. El heap incluye objetos del adaptador y runtime de prueba.

## Evaluación

El volumen medido supera ampliamente el historial actual esperado por una sola
serie y no mostró un bloqueo local. El algoritmo sigue cargando todo el rango en
memoria; por tanto, un crecimiento mucho mayor debe volver a medirse antes de
desplegar.

No se justifican índices o materialización adicionales en esta fase. Si el
historial creciera, evaluar con evidencia:

- `EXPLAIN QUERY PLAN` en el entorno de staging;
- límites reales de CPU/memoria y tamaño de respuesta;
- procesamiento por ventana o SQL `LEAD()`;
- materialización únicamente si mantiene revisiones y cobertura.

La respuesta pública tiene como máximo 100 destinos posibles y se pagina; el
riesgo principal está en la lectura del historial, no en el tamaño del ranking.
