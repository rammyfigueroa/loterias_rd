# Creación de D1 de staging

Fecha: 2026-11-09.

## Autorización ejecutada

Se creó exclusivamente la base D1 autorizada para staging. No se creó ni
desplegó ningún Worker y no se ejecutaron migraciones, SQL o cargas de datos.

## Cuenta

- Account ID: `f171b568e3a3a203a09ef2fd6e337a2c`.
- Perfil Wrangler: `default`.
- Wrangler: 4.155.0.
- La cuenta fue verificada con `wrangler whoami` antes de la creación.

## Recurso

- Nombre: `sorteosdominicanos-db-staging`.
- UUID: `f31aac48-f437-4fd7-9691-a7e976010dc6`.
- Región: `ENAM`.
- Fecha remota de creación: `2026-11-10T01:18:05.967Z`.
- Tablas: 0.
- Lecturas y escrituras en las últimas 24 horas: 0.
- Replicación de lectura: desactivada.

El inventario previo estaba vacío, por lo que no existía una base duplicada con
ese nombre. El inventario posterior contiene exactamente esta base D1.

## Comando ejecutado

Desde `loterias_rd_api`:

```sh
WRANGLER_SEND_METRICS=false npx --no-install wrangler d1 create sorteosdominicanos-db-staging --config wrangler.staging.toml
```

No se utilizó `--update-config`; el UUID fue revisado antes de editar el archivo.

## Configuración local

Se modificó únicamente el valor `database_id` de
`loterias_rd_api/wrangler.staging.toml`:

```toml
[[d1_databases]]
binding = "HISTORY_DB"
database_name = "sorteosdominicanos-db-staging"
database_id = "f31aac48-f437-4fd7-9691-a7e976010dc6"
migrations_dir = "migrations"
```

El nombre del Worker, cuenta, rutas, variables, triggers y controles de acceso
no fueron modificados en esta fase.

## Verificación

`wrangler d1 list` y `wrangler d1 info` confirmaron nombre, UUID, región y base
vacía. La primera consulta `d1 info` previa a la edición resolvió el UUID cero de
la plantilla y recibió el error esperado `7404`; después de actualizar el UUID,
la misma consulta terminó correctamente.

La versión activa del Worker de producción `api` fue inspeccionada en modo de
solo lectura. Sus bindings siguen limitados a tres variables de texto y no
incluyen D1 ni `HISTORY_DB`. Por tanto, la nueva base no está compartida ni
vinculada con producción.

## Recursos no modificados

- Worker `api`.
- Worker `sorteosdominicanos-app`.
- Worker futuro `sorteosdominicanos-api-staging`, que aún no existe.
- `wrangler.toml` de producción.
- DNS, rutas, variables y secretos remotos.
- Flutter, Android, iOS y motor estadístico.
- Migraciones y datos.

## Próximo paso recomendado

Auditar la lista de migraciones y preparar una fase separada que autorice
aplicarlas exclusivamente a este UUID. No crear ni desplegar el Worker hasta
tener Cloudflare Access aprobado.
