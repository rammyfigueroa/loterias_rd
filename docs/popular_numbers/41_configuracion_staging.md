# Configuración independiente de staging

Fecha: 2026-11-09.

## Archivo preparado

`loterias_rd_api/wrangler.staging.toml` es la única configuración destinada a
staging. La plantilla queda deliberadamente no desplegable hasta que exista un
D1 real y su identificador sea revisado.

## Identidad

- Cuenta: `f171b568e3a3a203a09ef2fd6e337a2c`.
- Worker: `sorteosdominicanos-api-staging`.
- Main: `src/index.js`.
- Compatibilidad: `2026-10-01`.
- Entorno lógico: `ENVIRONMENT=staging`.

No usa los nombres `api` ni `loterias-rd-api`. Fijar `account_id` evita que un
perfil con acceso a varias cuentas seleccione otra por omisión, pero no sustituye
la revisión previa de `wrangler whoami`.

## Exposición y triggers

- `workers_dev = false`.
- `preview_urls = false`.
- No hay `route` ni `routes`.
- `[triggers].crons = []` deshabilita cron explícitamente.
- No hay secretos declarados.

Sin una ruta o dominio futuro, el Worker no tendría un endpoint público normal.
La ruta de acceso debe decidirse y protegerse antes del primer despliegue.

## D1 futuro

```toml
[[d1_databases]]
binding = "HISTORY_DB"
database_name = "sorteosdominicanos-db-staging"
database_id = "00000000-0000-0000-0000-000000000000"
migrations_dir = "migrations"
```

El UUID cero es un marcador visible, no un identificador provisional válido. No
debe reemplazarse hasta que Cloudflare cree la base y una revisión humana
confirme:

1. cuenta correcta;
2. nombre exacto;
3. UUID no cero;
4. ausencia del UUID en producción;
5. configuración de staging como destino explícito.

Las migraciones permanecen en `loterias_rd_api/migrations`. No se creó ni aplicó
ninguna migración en esta fase.

## Fuente y datos

`SOURCE_URL` apunta a `https://staging.invalid/`, dominio reservado que impide
consultar accidentalmente al proveedor real. Las pruebas de historial y
transiciones deben usar exclusivamente fixtures sintéticos cargados en D1.

No se copiará D1, resultados ni secretos de producción. El endpoint `/results`
no forma parte de las pruebas de staging histórico mientras la fuente permanezca
bloqueada.

## Riesgos detectados en scripts

- `npm run deploy` ejecuta `wrangler deploy` con configuración implícita y puede
  crear el Worker local `loterias-rd-api`. No apunta al Worker real `api`, pero
  sigue siendo un comando remoto ambiguo y no debe utilizarse para staging.
- `npm run staging:dry-run` sí especifica `wrangler.staging.toml`, pero contiene
  la palabra `deploy`; no se ejecutó en esta fase.
- `npm run db:migrate:local` usa explícitamente `gana-mas-history-dev` y no es un
  comando de staging remoto.
- Los README históricos contienen comandos de despliegue generales; no son una
  autorización operativa.

No se modificó `package.json` para evitar alterar flujos existentes de
producción. Los comandos futuros deben escribirse completos y con `--config`.

## Convención oficial

Todos los recursos nuevos propuestos usan el identificador
`sorteosdominicanos`:

- Worker: `sorteosdominicanos-api-staging`;
- D1: `sorteosdominicanos-db-staging`;
- configuración: `wrangler.staging.toml`.

Los nombres `sorteosdominicanos-history-staging` y
`sorteosdominicanos-history-staging-db` que aparecen en documentos de fases
anteriores son referencias históricas y no están autorizados para recursos
nuevos. No se renombra ningún recurso remoto porque esos recursos no existen.

## Bloqueos

- D1 staging inexistente.
- UUID real pendiente.
- Worker staging inexistente.
- Política Cloudflare Access pendiente.
- Ruta o Custom Domain privado pendiente, si se decide usar uno.
- Fixture sintético remoto revisado pendiente.
