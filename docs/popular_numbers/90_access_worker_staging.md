# Access del Worker staging

Fecha: 2026-11-09.

## Alcance autorizado

Se creó una única aplicación Cloudflare Access vinculada exclusivamente al
Worker:

```text
sorteosdominicanos-api-staging
```

Cuenta Cloudflare:

```text
f171b568e3a3a203a09ef2fd6e337a2c
```

No se habilitaron entradas HTTP, rutas, dominios, previews ni `workers.dev`.

## Aplicación Access

- Nombre: `sorteosdominicanos-api-staging - Cloudflare Workers`.
- Tipo: `Self-hosted`.
- Application ID: `dec22f7c-f1bd-46c9-a5a0-15b05b98cbad`.
- Destino: Worker `sorteosdominicanos-api-staging`.
- Alcance del Worker: `All traffic`.
- Cobertura mostrada por Cloudflare: producción y previews del Worker.
- Duración de sesión: 24 horas.
- Team domain: `sorteosdominicanos.cloudflareaccess.com`.
- AUD tag:
  `381a3b3cdcb9b2726fa95732eb62233d56a976f5a80fbfa914f6fddb14739766`.

La asociación se creó desde la pestaña Access del Worker exacto. No se usaron
el deployment ID, el version ID ni el UUID de D1 como identificador del
destino.

## Política

- Nombre: `sorteosdominicanos staging admin`.
- Policy ID: `b8fc62ea-3d4a-49d7-ba07-09fc1204f0f8`.
- Acción: `Allow`.
- Reglas: 1.
- Aplicaciones que la utilizan: 1.
- Identidad: una dirección administrativa exacta, confirmada en el panel.

La dirección no se registra en este documento. No se utilizaron `Everyone`,
`Bypass`, dominios de correo amplios ni acceso anónimo. Cloudflare aplica
denegación predeterminada a las identidades que no coincidan con la regla.

## Autenticación

La aplicación conserva los proveedores de identidad disponibles en la
organización Zero Trust. El panel confirmó una única política de identidad
exacta; no se crearon usuarios, credenciales, service tokens ni secrets.

## Exposición

Después de aplicar Access, el panel del Worker continuó mostrando:

- `No URLs enabled`;
- `workers.dev Disabled`;
- Custom Domains: ninguno;
- Routes: ninguna;
- Domains: 0;
- Workers: 0;
- Queues: 0.

Access protege el Worker, pero no constituye una entrada pública. La aplicación
queda preparada para una fase posterior que habilite una única entrada de forma
controlada y pruebe acceso autorizado y denegado.

## Recursos no modificados

- Worker de producción `api`.
- Aplicación `sorteosdominicanos-app`.
- D1 staging y su fixture sintético.
- D1 de producción.
- DNS, rutas y Custom Domains.
- Configuración de Wrangler.
- Código Flutter y backend.
- Facturación y secretos.

## Próximo paso

Mantener el Worker sin URLs. Una fase separada debe autorizar una única entrada,
comprobar que una petición anónima sea redirigida o denegada por Access y validar
el acceso de la identidad administrativa autorizada.
