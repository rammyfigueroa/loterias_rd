# Política Access propuesta para staging

Fecha: 2026-11-09.

## Alcance

Esta propuesta protege exclusivamente el futuro Worker
`sorteosdominicanos-api-staging` de la cuenta
`f171b568e3a3a203a09ef2fd6e337a2c`.

No se creó ninguna aplicación ni política Access. Tampoco se creó o desplegó
el Worker.

## Identidad propuesta

La política debe autorizar una sola identidad administrativa mediante:

- proveedor de identidad: Cloudflare, ya configurado en la organización;
- selector de política: dirección de correo individual exacta;
- valor: la dirección administrativa que el propietario confirme manualmente
  durante la fase de creación.

La dirección no se registra en este repositorio. El dato exacto permanece
pendiente y debe comprobarse en el momento de configurar la política.

El selector `Cloudflare Account Member` por sí solo no garantiza una única
identidad si la cuenta incorpora más miembros. Puede utilizarse como requisito
adicional si el panel lo permite, pero no debe sustituir el selector de correo
exacto.

One-time PIN no es necesario para la propuesta actual. Cloudflare es el
proveedor predeterminado observado. Agregar OTP constituiría otra modificación
de identidad y requeriría autorización independiente.

## Política propuesta

- Nombre sugerido: `sorteosdominicanos staging admin`.
- Acción: `Allow`.
- Include: un correo individual exacto.
- Proveedor de inicio de sesión: Cloudflare.
- Alcance: aplicación del Worker completo.
- Sesión: corta y explícitamente revisada antes de guardar.
- `Everyone`: no.
- Dominio de correo: no.
- `Bypass`: no.
- Acceso anónimo: no.
- `Service Auth`: no en esta fase.

Access aplica denegación predeterminada: cualquier identidad que no coincida
con la regla `Allow` permanece bloqueada. No hace falta una regla `Deny`
general adicional.

## Aplicación futura

La aplicación debe utilizar el destino de Worker completo:

```text
type = worker
worker_id = identificador real del Worker staging
traffic = All traffic
```

El `worker_id` no existe todavía y no debe inventarse. La aplicación no debe
apuntar a `api`, `sorteosdominicanos-app`, `all_workers` ni
`all_preview_workers`.

La protección a nivel del Worker cubre sus rutas, Custom Domains, hostname
`workers.dev` y previews. No se debe crear una aplicación más específica por
hostname o path con reglas menos restrictivas, porque una regla más específica
tiene precedencia.

## Rutas protegidas

No habrá excepciones por ruta:

- `/health`: requiere Access;
- `/statistics/*`: requiere Access;
- `/history` y `/history/coverage`: requieren Access;
- `/internal/history/backfill`: requiere Access y conserva además su token
  interno;
- `/` y `/results`: requieren Access;
- rutas desconocidas: Access se evalúa antes del `404` del Worker.

El token interno de backfill es defensa adicional y no sustituye Access. No se
debe configurar `Bypass` para health checks.

## Fuentes oficiales

- https://developers.cloudflare.com/workers/configuration/cloudflare-access/
- https://developers.cloudflare.com/cloudflare-one/access-controls/policies/
- https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/cloudflare/
- https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/one-time-pin/
