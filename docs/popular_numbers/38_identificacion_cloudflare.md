# Identificación de Cloudflare

Fecha: 2026-11-09.

## Alcance y método

La investigación utilizó exclusivamente mecanismos oficiales de Wrangler
4.155.0, resolución DNS y peticiones HTTP públicas sin datos de usuarios. No se
leyeron ni copiaron tokens, no se modificó la sesión y no se ejecutó ninguna
operación remota de escritura.

## Sesión y cuentas accesibles

- Perfil Wrangler activo: `default`.
- Perfiles adicionales: ninguno.
- Cuentas accesibles reportadas por `wrangler whoami`: una.
- Cuenta activa: `f171b568e3a3a203a09ef2fd6e337a2c`.
- Autenticación: OAuth administrado por Wrangler.
- El correo del usuario fue confirmado por Wrangler, pero se omite aquí por
  minimización de datos personales.

No hay variables de entorno `CLOUDFLARE_*`, `CF_*` o `WRANGLER_*` seleccionando
otra cuenta. Tampoco hay `account_id` declarado en las configuraciones locales.

## Configuraciones locales

### Backend principal declarado localmente

`loterias_rd_api/wrangler.toml` declara:

- nombre: `loterias-rd-api`;
- compatibilidad: `2025-01-01`;
- binding D1: `HISTORY_DB`;
- nombre D1: `gana-mas-history-dev`;
- ID D1: UUID cero de marcador;
- variables: `SOURCE_URL` y `CACHE_SECONDS`;
- sin rutas, dominios, triggers ni entornos nombrados.

Este nombre local no coincide con el Worker de producción encontrado.

### Staging declarado localmente

`loterias_rd_api/wrangler.staging.toml` declara:

- nombre: `sorteosdominicanos-history-staging`;
- compatibilidad: `2026-10-01`;
- `workers_dev = true` y previews desactivadas;
- binding `HISTORY_DB` hacia `sorteosdominicanos-history-staging-db`;
- ID D1: UUID cero de marcador;
- variable `ENVIRONMENT = "staging"`;
- sin rutas ni triggers.

### Aplicación web

`loterias_rd_app/wrangler.jsonc` declara:

- nombre: `sorteosdominicanos-app`;
- compatibilidad: `2026-06-30`;
- assets desde `web`;
- observabilidad habilitada;
- sin D1 ni variables declaradas.

## Recursos remotos identificados

### Backend de producción

- Worker real: `api`.
- Cuenta propietaria accesible: `f171b568e3a3a203a09ef2fd6e337a2c`.
- Despliegue activo: 100 % de la versión 5.
- Version ID activo: `9e4621b3-1d47-433a-b6e8-25c22de74d87`.
- Fecha del despliegue activo: 2026-06-30.
- Dominio confirmado: `api.sorteosdominicanos.workers.dev`.
- `/health` responde con servicio `loterias-rd-api`.
- Runtime: compatibilidad `2026-06-29`, `nodejs_compat`.
- Handler: `fetch`; no se observó handler `scheduled` en la versión activa.
- Bindings activos: solo `CACHE_SECONDS`, `FETCH_TIMEOUT_MS` y `MIN_RESULTS`,
  todos de texto plano.
- Binding D1: ninguno.

Por tanto, el backend público actual no usa la D1 histórica declarada en el
checkout local. No se consultó el contenido de `/results`.

### Aplicación web

- Worker: `sorteosdominicanos-app`.
- Despliegue activo: versión 1 al 100 %.
- Version ID: `c020326d-661b-4f34-a862-44ba013d388e`.
- Tipo: Worker de assets estáticos, sin bindings.
- Dominio confirmado: `sorteosdominicanos-app.sorteosdominicanos.workers.dev`.
- Responde HTTP 200.

### D1 y Pages

- Bases D1 visibles en la cuenta: ninguna.
- Proyectos Pages visibles: ninguno.
- D1 principal histórica: no localizada porque no existe una D1 visible y los
  TOML usan IDs de marcador.

### Rutas y dominios

- Los dos dominios `workers.dev` anteriores están confirmados públicamente.
- `sorteosdominicanos.app` y `www.sorteosdominicanos.app` no resolvieron DNS.
- No se encontraron rutas ni custom domains declarados en los archivos locales.
- Wrangler 4.155.0 no ofrece un comando de solo lectura para inventariar todas
  las rutas/custom domains. No se usaron credenciales fuera de Wrangler para
  consultar APIs adicionales; por ello no se afirma la ausencia absoluta de
  otros dominios no conocidos.

## Staging

- Worker `sorteosdominicanos-history-staging`: no existe en la cuenta activa.
- Su URL candidata devuelve 404 de Cloudflare.
- D1 `sorteosdominicanos-history-staging-db`: no existe en el inventario D1.
- No hay bindings, rutas, datos ni protección remota que auditar.

## Limitación del inventario

Wrangler permitió verificar directamente todos los nombres relevantes obtenidos
del repositorio y del endpoint público. No se realizó un listado general de
scripts ajenos al proyecto porque esta versión de Wrangler no expone ese comando.
La identificación de la infraestructura de Sorteos Dominicanos sí es suficiente:
`api` y `sorteosdominicanos-app` están en la única cuenta accesible.
