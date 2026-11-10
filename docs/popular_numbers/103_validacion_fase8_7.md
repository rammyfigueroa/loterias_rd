# Validación de la Fase 8.7

Fecha: 2026-11-09.

## Resultado

Se auditó la conexión futura Flutter–Worker y se diseñó una arquitectura que
mantiene staging administrativo separado de una futura API pública de lectura.
No se implementó HTTP ni se modificó infraestructura.

## Hallazgos principales

- Flutter dispone de repositorio, controlador y UI reutilizables.
- El contrato Worker contiene más estados y metadatos que el modelo local.
- Staging está protegido por Access y contiene solo fixtures sintéticos.
- Credenciales Access no son aptas para distribución en Flutter.
- El Worker público `api` no tenía D1 en la última auditoría confirmada.
- `wrangler.toml` contiene un UUID marcador y no representa producción.
- No existe historial real aprobado para habilitar la función.

## Arquitectura aprobable para una fase futura

1. datos reales autorizados en D1 dedicada;
2. entrypoint público estrictamente de solo lectura;
3. motor y D1 internos sin rutas administrativas públicas;
4. validación exacta, rate limiting, caché y observabilidad;
5. cliente Flutter sin secretos y con parser completo;
6. feature flag activada solo después de validación de producción.

## Secuencia de despliegue propuesta

1. Resolver procedencia, derechos y cobertura histórica real.
2. Aprobar D1 y cargar datos mediante proceso controlado.
3. Congelar y validar versión del contrato.
4. Implementar parser, remote source y repositorio HTTP localmente.
5. Ejecutar pruebas unitarias, contrato, integración y seguridad.
6. Preparar entrypoint público de lectura y controles contra abuso.
7. Desplegar backend sin activar Flutter.
8. Validar datos, caché, límites, errores y rutas negativas en producción.
9. Configurar URL pública en build de revisión.
10. Activar la feature flag en una versión separada.
11. Validar en dispositivo y publicar Flutter mediante proceso autorizado.

Cada paso requiere aprobación propia; un fallo de procedencia, contrato,
aislamiento o seguridad detiene la secuencia.

## Pruebas requeridas antes de conexión

- contrato y serialización;
- respuestas válidas, incompletas y vacías;
- HTTP, timeout y reintentos;
- paginación y revisión;
- caché e invalidación;
- cambio de filtros y respuesta tardía;
- aislamiento de series y entornos;
- ausencia de credenciales;
- rutas administrativas inaccesibles;
- fixture sintético ausente de producción;
- descargo no predictivo y cobertura visibles.

## Operaciones no realizadas

- cambios Flutter: ninguno;
- cambios Worker/D1/Access/DNS: ninguno;
- migraciones/backfill: ninguno;
- pruebas contra staging: ninguna;
- despliegues/builds: ninguno;
- feature flags activadas: ninguna;
- commits/push/PR: ninguno.

## Recomendación para Fase 8.8

La siguiente fase no debe comenzar por Flutter. Debe resolver primero el
inventario y autorización de datos históricos reales y elegir formalmente el
entrypoint público de solo lectura. Solo después corresponde congelar el
contrato v1 y autorizar la implementación del repositorio HTTP.

**ARQUITECTURA DISEÑADA — DATOS REALES Y API PÚBLICA PENDIENTES**
