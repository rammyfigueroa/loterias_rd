# Auditoría de Cloudflare Access para staging

Fecha: 2026-11-09.

## Estado verificado

- Cuenta: `f171b568e3a3a203a09ef2fd6e337a2c`.
- Worker previsto: `sorteosdominicanos-api-staging`.
- El Worker no existe: Wrangler devolvió el código 10007 al consultar sus
  deployments.
- D1: `sorteosdominicanos-db-staging`.
- UUID: `f31aac48-f437-4fd7-9691-a7e976010dc6`.
- Binding: `HISTORY_DB`.
- D1: 16 resultados, 19 coberturas, 1 revisión y cero violaciones de claves
  foráneas.
- Configuración: `workers_dev = false`, `preview_urls = false`, sin rutas,
  Custom Domains, cron o secretos.

La sesión oficial de Wrangler usa OAuth y corresponde a la cuenta esperada. Los
permisos informados permiten consultar Workers y D1, pero no incluyen permisos
de lectura o escritura de Access Apps and Policies. Por ello no fue posible
enumerar de forma autenticada organizaciones Zero Trust, aplicaciones,
políticas, proveedores de identidad o restricciones concretas del plan.

## Disponibilidad de la función

Cloudflare documenta soporte para Access a nivel de Worker. Una regla de este
tipo cubre rutas, Custom Domains, hostname `workers.dev` y previews asociados al
Worker. También existe protección por hostname y una regla a nivel de cuenta
para todos los Workers.

La disponibilidad del producto está confirmada. Su habilitación y configuración
en esta cuenta quedan **NO DETERMINABLES** hasta inspeccionarlas con permisos
oficiales de Access o desde el dashboard Zero Trust.

## Opciones evaluadas

### A. Access sobre `workers.dev`

Técnicamente soportada, pero no está activa: `workers_dev` permanece en `false`.
No debe habilitarse antes de asociar Access al Worker completo y verificar su
política. Una aplicación limitada al hostname no protege otras entradas más
específicas que puedan añadirse después.

### B. Custom Domain exclusivo

Técnicamente soportado, pero no hay un hostname de staging autorizado ni una
configuración DNS aprobada. Requeriría una zona disponible, DNS/certificado y
una aplicación Access para ese hostname o para el Worker completo. No es viable
en esta fase.

### C. Sin superficie pública

Es la opción viable y recomendada hoy. Con `workers_dev=false`, previews
desactivadas y cero rutas, un despliegue no tendría una entrada HTTP normal. El
Worker oculto podría recibir una política Access a nivel de Worker antes de
habilitar cualquier hostname.

## Superficies auditadas

El Worker contiene rutas públicas de lectura (`/`, `/results`, `/health`,
`/history`, `/history/coverage` y estadísticas) y una ruta administrativa
`POST /internal/history/backfill`. Esta última también exige
`HISTORY_BACKFILL_TOKEN`, pero esa comprobación interna no sustituye Access.

No hay una ruta actual que pueda eludir Access porque el Worker no existe y no
tiene ingress. Si se habilitara solo Access por hostname, una nueva ruta,
Custom Domain, `workers.dev` o preview no cubierta podría convertirse en bypass.
Por eso se recomienda protección a nivel de Worker para todo el tráfico.

## Fuentes oficiales

- [Cloudflare Access para Workers](https://developers.cloudflare.com/workers/configuration/cloudflare-access/)
- [Rutas y dominios de Workers](https://developers.cloudflare.com/workers/configuration/routing/)
- [Custom Domains y previews](https://developers.cloudflare.com/workers/previews/custom-domains/)
- [Políticas Access](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/)
- [Límites de Cloudflare One](https://developers.cloudflare.com/cloudflare-one/account-limits/)
- [Logs de autenticación Access](https://developers.cloudflare.com/cloudflare-one/insights/logs/dashboard-logs/access-authentication-logs/)
