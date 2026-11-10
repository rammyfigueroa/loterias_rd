# Seguridad de staging

Fecha: 2026-11-09.

## Estado observado

- Wrangler está autenticado mediante la sesión OAuth existente.
- No se leyó, imprimió ni copió el contenido de credenciales.
- La sesión posee permisos de escritura amplios; esta fase utilizó únicamente
  consultas de solo lectura.
- No se detectaron patrones evidentes de claves privadas, contraseñas, tokens o
  secretos asignados dentro del repositorio revisado.
- `HISTORY_BACKFILL_TOKEN` solo aparece como nombre/documentación; no hay valor
  comprometido.
- No existen Worker ni D1 de staging en la cuenta consultada.

## Modelo de amenazas

1. Ejecutar por error Wrangler sin `--config wrangler.staging.toml`.
2. Sustituir el UUID cero por un ID de producción.
3. Publicar GET históricos/estadísticos mediante `workers.dev` sin restricción.
4. Exponer el token de backfill en shell, logs, documentación o Git.
5. Activar el handler `scheduled` mediante un trigger no revisado.
6. Ejecutar backfill contra el proveedor en vez de cargar fixtures sintéticos.
7. Confundir nombres de recursos con identidad comprobada.
8. Registrar payloads, headers o datos sensibles durante observabilidad.

## Controles requeridos antes de 8.5B

- Manifiesto aprobado con cuenta, nombre e ID de Worker y D1 de staging.
- Comparación explícita contra todos los IDs de producción conocidos.
- Configuración dedicada pasada siempre con `--config`.
- Sin rutas, custom domains ni cron.
- Decisión de acceso: preferentemente acceso restringido; si se usa una URL
  pública temporal, limitar duración, datos y alcance y obtener aprobación.
- Secreto de backfill creado solo si se va a probar esa ruta; para fixtures
  sintéticos puede mantenerse sin configurar y el backfill seguirá denegado.
- Carga de fixtures con verificación previa del ID y transacción/idempotencia.
- Logs con lista permitida de campos, nunca cuerpo o headers completos.
- Revisión final de `git diff`, configuración y recursos antes de cada comando
  remoto de escritura.

## Separación de entornos

La separación propuesta usa nombres distintos, pero actualmente no existe una
identidad remota que la garantice. El binding `HISTORY_DB` puede conservar el
mismo nombre lógico siempre que el `database_id` remoto sea exclusivo. La
variable `ENVIRONMENT=staging` es informativa y no es un control de seguridad.

No debe considerarse seguro un despliegue hasta verificar simultáneamente:

- cuenta Cloudflare correcta;
- script de destino correcto;
- ID D1 no cero y exclusivo;
- ausencia de rutas/triggers;
- política de acceso aprobada;
- dataset exclusivamente sintético.

## Secretos y permisos

- No guardar secretos en TOML, `.env`, comandos, URLs, scripts o documentación.
- Usar el mecanismo interactivo de secretos de Wrangler solo bajo autorización.
- No reutilizar secretos de producción.
- No ampliar permisos de la sesión.
- No solicitar contraseñas ni tokens al usuario.
- Si es posible en la fase operativa, utilizar credenciales de menor privilegio
  limitadas a los recursos de staging.

## Respuesta ante incidente

Detener inmediatamente las pruebas si se detecta un recurso compartido, una
escritura fuera de staging, exposición de secreto o datos no sintéticos.
Conservar logs mínimos, revocar el acceso comprometido mediante el proceso
administrativo autorizado y no eliminar recursos hasta recibir instrucciones.

## Acciones remotas no ejecutadas

- No se crearon Worker ni D1.
- No se aplicaron migraciones.
- No se ejecutó D1 remoto con escrituras.
- No se modificaron variables ni secretos.
- No se configuraron rutas, DNS, dominios o triggers.
- No hubo despliegue, backfill, publicación ni acceso a producción.
