# Activación HTTP de staging

Fecha: 2026-11-09.

## Entrada habilitada

Se habilitó exclusivamente la URL de producción `workers.dev` del Worker de
staging:

```text
https://sorteosdominicanos-api-staging.sorteosdominicanos.workers.dev
```

El panel confirmó simultáneamente:

- Production Worker URL: activada;
- `An Access policy applies to this URL`;
- Preview URLs: desactivadas;
- Custom Domains: ninguno;
- Routes: ninguna.

No se creó un Custom Domain, no se modificó DNS y no se habilitó ninguna otra
entrada.

## Protección Access

- Application ID: `dec22f7c-f1bd-46c9-a5a0-15b05b98cbad`.
- Aplicación: `sorteosdominicanos-api-staging - Cloudflare Workers`.
- Alcance: `All traffic`.
- Policy ID: `b8fc62ea-3d4a-49d7-ba07-09fc1204f0f8`.
- Política: `sorteosdominicanos staging admin`.
- Acción: `Allow`.
- Identidad: una única identidad administrativa exacta.

No se usaron `Everyone`, `Bypass`, dominios de correo ni acceso anónimo. La
identidad administrativa no se registra en la documentación.

## Verificación anónima

Se realizaron solicitudes sin cookies, tokens ni credenciales a:

```text
/health
/statistics/number-transitions
```

Ambas devolvieron `HTTP 302` hacia el dominio oficial de inicio de sesión:

```text
sorteosdominicanos.cloudflareaccess.com
```

Las respuestas incluyeron `WWW-Authenticate: Cloudflare-Access` y HTML de
Cloudflare. No incluyeron JSON de `/health` ni resultados estadísticos, por lo
que el Worker no se ejecutó para las solicitudes anónimas.

## Verificación administrativa

El propietario completó el flujo oficial `Sign in with Cloudflare`. No se
extrajeron cookies, tokens ni credenciales.

La consulta autenticada a `/health` respondió:

```json
{
  "ok": true,
  "service": "loterias-rd-api"
}
```

Esto confirma que Access permitió la identidad autorizada y que la entrada
ejecuta el Worker de staging correcto.

## Estado final

La URL queda habilitada y protegida por Access. La única superficie HTTP es la
URL de producción `workers.dev`; previews, rutas y dominios adicionales siguen
desactivados.
