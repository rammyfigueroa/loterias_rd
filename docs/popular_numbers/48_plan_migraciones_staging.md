# Plan de migraciones para staging

Fecha: 2026-11-09.

## Alcance

Este procedimiento futuro se limita a:

- cuenta `f171b568e3a3a203a09ef2fd6e337a2c`;
- D1 `sorteosdominicanos-db-staging`;
- UUID `f31aac48-f437-4fd7-9691-a7e976010dc6`;
- configuración `wrangler.staging.toml`;
- migraciones 0001 y 0002 existentes.

Los comandos siguientes no fueron ejecutados en remoto y requieren autorización
explícita de otra fase.

## 1. Verificación previa

```sh
npx --no-install wrangler whoami
npx --no-install wrangler d1 list --json --config wrangler.staging.toml
npx --no-install wrangler d1 info sorteosdominicanos-db-staging --json --config wrangler.staging.toml
npx --no-install wrangler d1 migrations list sorteosdominicanos-db-staging --remote --config wrangler.staging.toml
```

Comprobar manualmente cuenta, nombre y UUID. La base debe seguir sin tablas
funcionales y la lista debe ofrecer exactamente:

1. `0001_gana_mas_history.sql`;
2. `0002_national_history.sql`.

## 2. Aplicación propuesta

Solo después de la revisión previa:

```sh
npx --no-install wrangler d1 migrations apply sorteosdominicanos-db-staging --remote --config wrangler.staging.toml
```

No usar un binding genérico, configuración implícita, `wrangler.toml` ni el
nombre de ningún recurso de producción.

## 3. Comprobaciones posteriores

```sh
npx --no-install wrangler d1 migrations list sorteosdominicanos-db-staging --remote --config wrangler.staging.toml
npx --no-install wrangler d1 info sorteosdominicanos-db-staging --json --config wrangler.staging.toml
npx --no-install wrangler d1 execute sorteosdominicanos-db-staging --remote --config wrangler.staging.toml --command "SELECT type, name, tbl_name FROM sqlite_master WHERE type IN ('table','index') ORDER BY type, name"
npx --no-install wrangler d1 execute sorteosdominicanos-db-staging --remote --config wrangler.staging.toml --command "SELECT id, name, enabled FROM draws ORDER BY id; SELECT COUNT(*) AS result_count FROM first_prize_results; SELECT COUNT(*) AS coverage_count FROM coverage; SELECT COUNT(*) AS revision_count FROM result_revisions"
```

Esperado:

- ninguna migración pendiente;
- seis tablas funcionales;
- seis índices explícitos más índices automáticos;
- operador Nacional y los sorteos Gana Más/Lotería Nacional habilitados;
- cero resultados, cobertura y revisiones.

Las consultas posteriores son de solo lectura. No cargar fixtures en esta fase.

## Criterios de aceptación

- cuenta, nombre y UUID exactos;
- base sin esquema inesperado antes de aplicar;
- lista exacta y ordenada de dos migraciones;
- ambas migraciones terminan correctamente;
- `d1_migrations` registra ambos archivos;
- tablas, índices y restricciones coinciden con la auditoría local;
- metadatos esperados y cero resultados históricos;
- Worker `api` y `sorteosdominicanos-app` sin cambios;
- ningún Worker creado o desplegado.

## Criterios de detención

Detenerse antes o durante la operación si ocurre cualquiera de estos casos:

- cuenta distinta;
- nombre o UUID diferente;
- tablas, índices o filas de resultados inesperados;
- migración previamente aplicada de forma parcial o no documentada;
- lista distinta de 0001 y 0002;
- error SQL o migración con estado ambiguo;
- diferencia entre esquema remoto y esquema local auditado;
- solicitud de crear Worker, insertar fixtures o ejecutar backfill;
- cualquier referencia a D1 o Worker de producción.

Ante un error no se debe improvisar rollback SQL. Wrangler conserva respaldo al
aplicar migraciones remotas; se debe detener, preservar la salida y solicitar
una revisión específica antes de restaurar o modificar datos.

## Siguiente etapa

Después de validar el esquema remoto, preparar en una fase independiente un
fixture sintético idempotente y revisable. No desplegar el Worker hasta aprobar
Cloudflare Access y la superficie de entrada.
