# Plan seguro de activación del Worker staging

Fecha: 2026-11-09.

## Orden propuesto

1. Confirmar en Zero Trust que Access está habilitado, identificar el plan y
   enumerar aplicaciones, políticas y proveedores de identidad existentes.
2. Confirmar que la identidad que administrará Access tiene permisos limitados
   a Apps and Policies y que el destino es la cuenta esperada.
3. Mantener `workers_dev=false`, `preview_urls=false`, cero rutas y cero Custom
   Domains.
4. Bajo autorización separada, desplegar el Worker oculto con
   `wrangler.staging.toml`. Sin ingress, no existe una URL normal pública durante
   esta ventana.
5. Asociar Access al Worker exacto con alcance `All traffic` y una política
   `Allow` explícita. No usar la protección global de todos los Workers.
6. Confirmar mediante la API/dashboard que la aplicación Access referencia el
   ID del Worker staging y no los Workers de producción.
7. Habilitar una sola entrada aprobada: preferiblemente un Custom Domain
   exclusivo; `workers.dev` solo si se autoriza expresamente.
8. Probar primero acceso anónimo y denegado. Si el Worker responde sin Access,
   deshabilitar inmediatamente la entrada y detenerse.
9. Probar acceso autorizado y todos los endpoints, incluida la denegación de
   backfill sin su segundo control interno.
10. Verificar que D1 conserva 16/19/1, claves foráneas válidas y cero escrituras
    inesperadas.

## Por qué evita una ventana pública

Cloudflare exige que el Worker exista para aplicar una regla a nivel de Worker.
La configuración actual permite crearlo sin hostname, preview, ruta o Custom
Domain. Access se adjunta mientras continúa sin ingress; la entrada se activa
solo después de comprobar la política.

No se recomienda activar la protección global `all_workers` para anticipar la
creación, porque podría afectar a `api` y `sorteosdominicanos-app`.

## Plan de pruebas

- anónimo: bloqueo o flujo Access antes del Worker;
- autorizado: respuesta esperada del endpoint;
- usuario autenticado no permitido: denegación;
- URL desconocida: Access primero, luego 404 del Worker si está autorizada;
- `/health`, `/results`, historia y estadísticas: todos protegidos;
- `/internal/history/backfill`: protegido por Access y por autorización interna;
- preview/version URL: inexistente mientras `preview_urls=false`;
- hostname alternativo: inexistente;
- errores: sin D1, JWT, cookies, tokens ni trazas internas;
- producción: `api` mantiene su comportamiento y despliegue sin cambios;
- D1: conteos e integridad sin alteraciones.

## Criterios de detención

- Zero Trust no habilitado o plan incompatible;
- ausencia de permisos Access necesarios;
- política que incluya `Everyone`, Bypass o un dominio demasiado amplio;
- Worker ID, cuenta, D1 o UUID distintos;
- aparición de preview, `workers.dev`, ruta o Custom Domain no revisado;
- cualquier cambio sobre producción;
- respuesta directa del Worker a una solicitud anónima;
- escritura inesperada en D1.
