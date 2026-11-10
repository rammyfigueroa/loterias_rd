# Validación de la Fase 8.5B-5

Fecha: 2026-11-09.

## Migraciones aplicadas

- [x] `0001_gana_mas_history.sql`.
- [x] `0002_national_history.sql`.
- [x] Orden correcto.
- [x] Sin errores SQL.
- [x] Sin migraciones pendientes.

## Estado D1

- Cuenta: `f171b568e3a3a203a09ef2fd6e337a2c`.
- Nombre: `sorteosdominicanos-db-staging`.
- UUID: `f31aac48-f437-4fd7-9691-a7e976010dc6`.
- Región: `ENAM`.
- Tablas funcionales: 6.
- Índices explícitos: 6.
- Historial `d1_migrations`: 2 registros.
- Tamaño reportado después de migrar: 106496 bytes.

## Validaciones de esquema

- Tablas esperadas presentes.
- Índices esperados presentes.
- Claves foráneas inspeccionadas.
- Índices automáticos de unicidad presentes.
- Operador y dos sorteos estructurados presentes.
- Resultados, cobertura, revisiones y backfill: 0 filas.
- Datos personales: ninguno.

## Aislamiento confirmado

- Producción `api` conserva despliegue y bindings anteriores.
- `api` no tiene binding D1.
- `sorteosdominicanos-app` conserva su despliegue.
- `sorteosdominicanos-api-staging` no existe.
- D1 staging no está vinculada a ningún Worker.

## Escrituras autorizadas

La única escritura remota fue la aplicación de las dos migraciones autorizadas.
Todas las comprobaciones posteriores fueron consultas de solo lectura y
reportaron `changed_db: false`.

## Operaciones no realizadas

- Sin fixtures, resultados o backfill.
- Sin creación o despliegue de Workers.
- Sin cambios de bindings, DNS, rutas, Access, variables o secretos.
- Sin modificaciones de Flutter, motor o configuración de producción.
- Sin commit, push o Pull Request.

## Validación local

`git diff --check` debe permanecer aprobado. La documentación no incluye
credenciales y los cambios previos del árbol de trabajo se conservan.

## Próxima fase

Diseñar y validar localmente un fixture sintético idempotente. La carga remota
de ese fixture debe requerir otra autorización limitada. El Worker continúa
bloqueado hasta definir y configurar Cloudflare Access.

## Decisión

**ESQUEMA D1 STAGING APLICADO Y VERIFICADO — SIN DATOS NI WORKER**
