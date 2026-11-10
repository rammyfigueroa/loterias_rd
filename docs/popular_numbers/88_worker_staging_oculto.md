# Worker staging sin exposición pública

Fecha: 2026-11-09.

## Alcance autorizado

Se creó y desplegó exclusivamente el Worker:

```text
sorteosdominicanos-api-staging
```

Cuenta:

```text
f171b568e3a3a203a09ef2fd6e337a2c
```

Se utilizó únicamente:

```text
loterias_rd_api/wrangler.staging.toml
```

No se modificó la configuración antes del despliegue.

## Verificación previa

Wrangler confirmó:

- cuenta correcta;
- Worker inexistente antes de esta fase, código remoto `10007`;
- D1 `sorteosdominicanos-db-staging`;
- UUID `f31aac48-f437-4fd7-9691-a7e976010dc6`;
- binding `HISTORY_DB`;
- `workers_dev = false`;
- `preview_urls = false`;
- sin rutas;
- sin Custom Domains;
- `crons = []`;
- sin secrets declarados.

La inspección remota de solo lectura confirmó que el fixture sintético ya
existía con 16 resultados, 19 registros de cobertura y 1 revisión. No se
ejecutaron escrituras en D1.

## Dry-run

Comando ejecutado:

```sh
npx wrangler deploy --dry-run --config wrangler.staging.toml
```

Resultado:

- estado: correcto;
- carga total: `81.36 KiB`;
- gzip: `18.96 KiB`;
- binding remoto: solamente `HISTORY_DB`;
- variables no secretas: `ENVIRONMENT`, `SOURCE_URL`, `CACHE_SECONDS`;
- rutas o targets: ninguno.

## Despliegue

Comando ejecutado:

```sh
npx wrangler deploy --config wrangler.staging.toml
```

Resultado de Wrangler:

- Worker subido: `sorteosdominicanos-api-staging`;
- startup: `3 ms`;
- targets desplegados: ninguno;
- deployment ID: `62246203-a1a9-4f3e-9808-0e6baea1f8cf`;
- version ID: `1cc2db30-e9d0-48e6-886d-28de07b918e5`;
- número de versión: `1`.

Wrangler identifica el servicio por su nombre exacto. El identificador que una
futura aplicación Access de tipo `worker` requiera debe obtenerse y verificarse
durante esa fase; no se inventó ni se dedujo de los UUID de deployment o
versión.

## Bindings confirmados

La versión remota expone al proceso únicamente:

- `HISTORY_DB`, tipo D1, UUID
  `f31aac48-f437-4fd7-9691-a7e976010dc6`;
- `ENVIRONMENT = staging`;
- `SOURCE_URL = https://staging.invalid/`;
- `CACHE_SECONDS = 180`.

No se encontraron secrets ni bindings de producción.

## Ausencia de exposición

Wrangler informó:

```text
No targets deployed for sorteosdominicanos-api-staging
```

La URL `workers.dev` correspondiente fue consultada únicamente para verificar
exposición y devolvió `HTTP 404` con `error code: 1042` de Cloudflare. No devolvió
la respuesta `/health` del Worker.

Aunque el metadato interno de la versión informa `has_preview: true`, la
configuración conserva `preview_urls = false` y el despliegue no creó targets.
No se habilitó una URL de preview, una ruta ni un Custom Domain.

## Estado de producción y D1

- Worker `api`: despliegues sin cambios observados.
- `sorteosdominicanos-app`: despliegue sin cambios observado.
- D1 staging: fixture `16/19/1`, estado `ALREADY_APPLIED`.
- Escrituras ejecutadas por la validación D1: ninguna.
- D1 de producción: no utilizada ni modificada.
- DNS: sin cambios.
- Access: sin aplicaciones ni políticas nuevas.

## Próximo paso

Mantener el Worker sin targets. La siguiente fase debe obtener el identificador
requerido por Access, crear la política restringida y asociar la aplicación al
Worker completo antes de habilitar una única entrada HTTP.
