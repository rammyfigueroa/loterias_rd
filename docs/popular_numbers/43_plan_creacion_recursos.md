# Plan de creación de recursos de staging

Fecha: 2026-11-09.

## Regla de ejecución

Todos los comandos de esta página son propuestas futuras. No fueron ejecutados.
Cada bloque requiere autorización explícita y una revisión entre etapas. Deben
ejecutarse desde `loterias_rd_api` con Wrangler 4.155.0 o una versión revisada.

## 1. Preflight de cuenta y ausencia de recursos

```sh
npx --no-install wrangler whoami
npx --no-install wrangler d1 list --json
npx --no-install wrangler deployments list --name sorteosdominicanos-api-staging --json
```

Detenerse si la cuenta no es `f171b568e3a3a203a09ef2fd6e337a2c`, si el nombre
ya existe inesperadamente o si aparece un D1 homónimo no documentado.

## 2. Crear D1 de staging

```sh
npx --no-install wrangler d1 create sorteosdominicanos-db-staging --config wrangler.staging.toml
```

No utilizar `--update-config`. Registrar el UUID devuelto fuera de logs públicos
y detenerse. Antes de editar la plantilla, verificarlo con:

```sh
npx --no-install wrangler d1 info sorteosdominicanos-db-staging --json --config wrangler.staging.toml
npx --no-install wrangler d1 list --json --config wrangler.staging.toml
```

La edición del UUID requiere una autorización posterior específica.

## 3. Revisar configuración

Confirmar localmente:

```sh
grep -nE '^(name|account_id|workers_dev|preview_urls)' wrangler.staging.toml
grep -nE '^(binding|database_name|database_id|migrations_dir)' wrangler.staging.toml
```

No continuar si aparece `name = "api"`, `name = "loterias-rd-api"`, UUID cero,
una ruta, un cron o una fuente real.

## 4. Aplicar migraciones

Solo después de verificar el UUID:

```sh
npx --no-install wrangler d1 migrations list sorteosdominicanos-db-staging --remote --config wrangler.staging.toml
npx --no-install wrangler d1 migrations apply sorteosdominicanos-db-staging --remote --config wrangler.staging.toml
```

Revisar la lista antes de confirmar. No usar binding/nombre de producción.

## 5. Cargar fixtures sintéticos

El archivo SQL todavía no existe y debe prepararse/revisarse en otra fase. El
comando futuro tendrá esta forma:

```sh
npx --no-install wrangler d1 execute sorteosdominicanos-db-staging --remote --config wrangler.staging.toml --file <FIXTURE_SINTETICO_REVISADO.sql>
```

El fixture debe ser idempotente, identificable como sintético, sin payloads de
producción y limitado a las series estructuradas de prueba.

## 6. Crear/desplegar el Worker

Wrangler crea el script durante el primer despliegue. No existe un comando
separado de creación que sea necesario. Antes de este paso deben estar aprobados
el D1, la configuración y Cloudflare Access.

```sh
npx --no-install wrangler deploy --config wrangler.staging.toml
```

La plantilla mantiene `workers_dev=false`, previews desactivadas, cero rutas y
cero cron. Si no existe una entrada protegida aprobada, el despliegue no debe
ejecutarse porque no habrá un endpoint de pruebas autorizado.

## 7. Revisar despliegue y bindings

```sh
npx --no-install wrangler deployments status --name sorteosdominicanos-api-staging --json --config wrangler.staging.toml
npx --no-install wrangler versions list --name sorteosdominicanos-api-staging --json --config wrangler.staging.toml
npx --no-install wrangler d1 info sorteosdominicanos-db-staging --json --config wrangler.staging.toml
```

Inspeccionar la versión activa para confirmar `HISTORY_DB`, variables no
sensibles, compatibilidad y ausencia de bindings inesperados.

## 8. Ejecutar pruebas

Las pruebas locales siguen siendo:

```sh
npm test
npm run staging:dev
```

Las pruebas remotas requieren una URL protegida y el plan del documento 35. No
se incluye aquí una URL ni credencial ficticia.

## Puntos de parada obligatorios

- Después de crear D1 y antes de editar el UUID.
- Antes de aplicar migraciones.
- Antes de configurar Access/rutas.
- Antes del primer despliegue.
- Antes de cargar fixtures.
- Ante cualquier referencia a `api` o `sorteosdominicanos-app`.
