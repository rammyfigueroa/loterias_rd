# Diseño de fixtures sintéticos de staging

Fecha: 2026-11-09.

## Alcance

Los fixtures validan localmente `Relaciones Históricas entre Números` sin usar
resultados reales, tablas comerciales, asociaciones populares o datos
personales. La implementación está en
`loterias_rd_api/scripts/staging-fixtures.js` y reutiliza las identidades
estructuradas del operador Nacional, Gana Más y Lotería Nacional.

No se modificaron las migraciones 0001 y 0002. El fixture se aplica después de
crear el esquema histórico en una D1 local efímera.

## Fixture base

Contenido:

- 16 resultados sintéticos: 10 de Gana Más y 6 de Lotería Nacional;
- 19 registros de cobertura: 11 de Gana Más y 8 de Lotería Nacional;
- una revisión sintética;
- un `NO_DRAW_SCHEDULED` con fuente de verificación sintética;
- un `NO_RESULTS_RETURNED` y un `UNVERIFIED` en la serie independiente;
- rangos cortos, último evento sin sucesor y números sin apariciones;
- datos suficientes para comprobar caché e invalidación por fingerprint;
- identidades estables con prefijo `synthetic-staging-v1`.

### Resultado manual de referencia

Secuencia de Gana Más:

| Fecha | Primera posición | Observación |
| --- | ---: | --- |
| 01/04/2026 | 24 | Evento |
| 02/04/2026 | 67 | Evento |
| 03/04/2026 | 24 | Evento |
| 04/04/2026 | 32 | Corrección sintética de 31 a 32 |
| 05/04/2026 | - | Sin sorteo, verificado sintéticamente |
| 06/04/2026 | 24 | Evento |
| 07/04/2026 | 67 | Evento |
| 08/04/2026 | 24 | Evento |
| 09/04/2026 | 67 | Evento |
| 10/04/2026 | 24 | Evento |
| 11/04/2026 | 24 | Último evento, sin sucesor |

Para el origen `24`:

| Destino | Conteo | Frecuencia relativa |
| ---: | ---: | ---: |
| 67 | 3 | 0.6 |
| 24 | 1 | 0.2 |
| 32 | 1 | 0.2 |

Total: 5 transiciones. El último `24` no entra en el denominador. Los destinos
`24` y `32` ejercitan un empate y el orden estable por número.

## Cobertura separada

Lotería Nacional contiene seis eventos entre el 01/05/2026 y el 08/05/2026.
El 03/05 se marca `NO_RESULTS_RETURNED` y el 06/05 `UNVERIFIED`. Esto permite
comprobar modos verificado e incompleto sin mezclar eventos de Gana Más.

## Corrección y revisión

El resultado canónico del 04/04/2026 es `32`. Una fila en
`result_revisions` conserva exclusivamente la versión sintética anterior `31`,
checksums, payloads y fecha fija de detección. La prueba exige que la revisión
apunte mediante clave foránea al resultado canónico.

## Fixture de rendimiento

`createPerformanceFixture()` genera 5,000 resultados y 5,000 registros de
cobertura para Gana Más, desde el 01/01/2010. El número se calcula con:

```text
(11 + índice * 37) módulo 100
```

No existe aleatoriedad ni dependencia del reloj. El patrón tiene ciclo 100 y,
para el origen `11`, produce 50 transiciones observadas hacia `48`, todas con
frecuencia relativa `1`. El contenido completo se genera en memoria, evitando
un archivo SQL grande.

## Idempotencia y colisiones

Antes de escribir, el cargador compara:

- `provider_result_id` y la pareja única sorteo/fecha;
- todos los campos canónicos del resultado;
- sorteo/fecha y todos los campos de cobertura;
- identidad y contenido de la revisión.

Una fila idéntica se conserva y no se reinserta. Cualquier colisión distinta
detiene la operación antes de insertar el fixture. No se usan `DELETE`,
`DROP`, `TRUNCATE`, actualizaciones masivas ni sobrescrituras.

Las inserciones se ejecutan en lotes de hasta 100 sentencias para soportar el
fixture de 5,000 eventos. Una ejecución interrumpida puede repetirse: las filas
ya verificadas se omiten y solo se insertan las filas sintéticas faltantes.
