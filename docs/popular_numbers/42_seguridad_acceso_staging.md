# Seguridad de acceso a staging

Fecha: 2026-11-09.

## Objetivo

Evitar que el endpoint de pruebas quede abierto al público y evitar que una
configuración de staging afecte `api` o `sorteosdominicanos-app`.

## Controles evaluados

### Cloudflare Access a nivel de Worker

Es la opción prioritaria. Cloudflare permite proteger un Worker completo y
aplicar la política a sus rutas, Custom Domains, hostname `workers.dev` y
previews. Requiere habilitar Zero Trust y crear una política remota, acciones no
autorizadas en esta fase.

Ventajas:

- control oficial previo a la ejecución del Worker;
- una política cubre los endpoints asociados al Worker;
- no requiere autenticación casera dentro del código;
- permite usuarios o identidades explícitamente autorizados.

Riesgos:

- una política mal dirigida puede proteger otro Worker;
- requiere permisos administrativos y revisión del destino exacto;
- debe comprobarse también el tratamiento de URLs de versión/preview.

### Access por hostname o Custom Domain

Es viable si se incorpora una zona Cloudflare y un hostname exclusivo. Un
Custom Domain es apropiado cuando el Worker es el origen. Access puede proteger
ese hostname, pero una regla de hostname no protege automáticamente otras URLs
del Worker si siguen habilitadas.

La cuenta no tiene actualmente `sorteosdominicanos.app` resolviendo en DNS. No
se propone crear DNS ni Custom Domain en esta fase.

### Deshabilitar `workers.dev`

La plantilla fija `workers_dev = false`, tal como admite Wrangler. Esto evita la
ruta normal `workers.dev` en un despliegue futuro. También se mantienen previews
desactivadas. Sin una ruta o Custom Domain, no existe una URL normal para probar;
por eso el mecanismo de entrada debe aprobarse antes del despliegue.

Cloudflare documenta que deshabilitar `workers.dev` no sustituye por sí solo la
protección de URLs de versión, preview o deployment. Access sigue siendo el
control recomendado si esas superficies se habilitan.

### Autenticación explícita en código

No se implementa. Un header o token desarrollado localmente aumentaría la
superficie de seguridad y requeriría cambios de backend, manejo de secretos,
pruebas y revisión. Solo se reconsideraría si Access no satisface el caso de uso.

## Estrategia recomendada

1. Mantener `workers_dev=false`, previews desactivadas y cero rutas en la
   plantilla.
2. Crear los recursos únicamente bajo autorización.
3. Proteger el Worker completo mediante Cloudflare Access antes de habilitar una
   superficie de entrada.
4. Permitir solo identidades de prueba aprobadas.
5. Verificar desde una sesión no autorizada que el Worker responde con bloqueo.
6. Verificar desde una sesión autorizada los endpoints de staging.
7. Mantener `api` explícitamente fuera de la política de staging.

## Requisitos de revisión

- ID/nombre exacto del Worker protegido.
- alcance de tráfico: producción del Worker de staging y previews solo si se
  habilitan posteriormente;
- política y miembros permitidos;
- duración de sesión;
- comportamiento para automatización de pruebas;
- ausencia de bypass público;
- verificación externa antes de cargar fixtures.

## Fuentes oficiales consultadas

- Cloudflare Workers: `https://developers.cloudflare.com/workers/configuration/routing/workers-dev/`.
- Cloudflare Access: `https://developers.cloudflare.com/workers/configuration/cloudflare-access/`.
- Cloudflare Custom Domains: `https://developers.cloudflare.com/workers/configuration/routing/custom-domains/`.
- Cloudflare D1: `https://developers.cloudflare.com/d1/wrangler-commands/`.

Las fuentes se consultaron para diseñar el plan. No se aplicó ninguna política
ni cambio remoto.
