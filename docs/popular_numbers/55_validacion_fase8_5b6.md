# Validación de la Fase 8.5B-6

Fecha: 2026-11-09.

## Implementación

- Generador y cargador idempotente: `scripts/staging-fixtures.js`.
- CLI local protegido: `scripts/load-staging-fixtures-local.js`.
- Comando npm: `fixtures:staging:local`.
- Pruebas nuevas: `test/staging-fixtures.test.js`.
- Migraciones modificadas: ninguna.

## Datos sintéticos

Fixture base:

- resultados: 16;
- cobertura: 19;
- revisiones: 1;
- series: 2, siempre separadas;
- resultados reales o comerciales: 0;
- datos personales: 0.

Fixture ampliado:

- resultados: 5,000;
- cobertura: 5,000;
- revisiones: 0;
- generación: determinista y sin reloj ni aleatoriedad.

## Resultados esperados confirmados

Para Gana Más, origen `24`, rango 01/04/2026–11/04/2026:

- `67`: 3, frecuencia 0.6;
- `24`: 1, frecuencia 0.2;
- `32`: 1, frecuencia 0.2;
- total: 5;
- una aparición final sin sucesor.

Para el fixture de rendimiento, origen `11`:

- `48`: 50, frecuencia 1;
- total: 50.

## Idempotencia e integridad

- Primera carga base: 16/19/1 inserciones.
- Segunda carga base: 0/0/0 inserciones.
- Claves foráneas: sin violaciones.
- Colisión ajena: rechazada sin sobrescritura.
- No existen operaciones de borrado o actualización masiva.
- No se modifican datos que no coincidan exactamente con el fixture.

## Validación

- Sintaxis Node: aprobada.
- Pruebas específicas: 11/11.
- Backend completo: 95/95.
- `git diff --check`: aprobado.
- D1 usada: local efímera.
- Configuración: staging explícita, bindings remotos desactivados.

## Riesgos pendientes

1. El cargador local no constituye autorización ni procedimiento remoto.
2. Una futura carga de 5,000 eventos debe revisar límites y duración en D1
   remota por separado.
3. El uso de `unstable_readConfig` depende de una API inestable de Wrangler y
   debe reevaluarse al actualizar esa dependencia.
4. La carga por lotes es reanudable, pero no es una única transacción global;
   después de una interrupción debe repetirse el preflight completo.
5. El fixture comparte IDs de series estructuradas, aunque todos sus resultados
   están marcados con fuente y prefijo sintéticos. Nunca debe confundirse con
   historial real.

## Cambios remotos

- Escrituras D1 remotas: ninguna.
- Inserciones en Cloudflare: ninguna.
- Workers creados o desplegados: ninguno.
- Producción, DNS, Access, rutas, bindings y secretos: sin cambios.
- Flutter y feature flag: sin cambios.
- Commit, push y Pull Request: no realizados.

## Recomendación

La siguiente fase debe revisar el fixture y decidir si autoriza una carga
remota limitada del fixture base únicamente. Antes de cualquier escritura debe
confirmarse nuevamente cuenta, UUID, esquema, ausencia de datos inesperados y
aislamiento. El fixture de rendimiento debería permanecer local salvo una
necesidad de prueba remota explícita y separada.

## Decisión

**FIXTURES SINTÉTICOS DISEÑADOS Y VALIDADOS LOCALMENTE — CARGA REMOTA NO AUTORIZADA**
