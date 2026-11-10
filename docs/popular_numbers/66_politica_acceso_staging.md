# Política propuesta para Access en staging

Fecha: 2026-11-09.

## Alcance

Aplicación Access vinculada al Worker exacto
`sorteosdominicanos-api-staging`, con destino de tipo `worker` y protección de
todo el tráfico de producción y preview del Worker. No debe aplicarse a `api`,
`sorteosdominicanos-app` ni a todos los Workers de la cuenta.

## Política humana

1. Access permanece denegado por defecto.
2. Crear una única política `Allow` para identidades de prueba explícitamente
   autorizadas mediante un proveedor de identidad oficial.
3. No usar `Everyone`, dominio de correo abierto ni cualquier login válido como
   condición suficiente.
4. No crear políticas `Bypass`; Cloudflare advierte que Bypass omite controles y
   logging de Access.
5. Usar una sesión corta para staging y revocarla al terminar la validación.
6. Revisar logs de autenticación exitosos y fallidos sin registrar tokens,
   cookies, JWT ni parámetros sensibles de la aplicación.

No se fija una dirección de correo en este documento. Las identidades permitidas
deben seleccionarse durante la revisión humana de la política.

## Automatización futura

Si una prueba automatizada necesita acceso, usar `Service Auth` y un service
token oficial separado. No reutilizar credenciales humanas ni crear un header
casero. La creación, almacenamiento y rotación del token requieren una fase
independiente.

## Defensa en profundidad

- Access debe ejecutarse antes del Worker.
- La ruta `/internal/history/backfill` conserva además su autorización interna.
- No deben existir excepciones por path para `/health`, estadísticas o rutas
  administrativas.
- `Access-Control-Allow-Origin: *` no concede acceso a través de Access, pero
  debe revisarse antes de un uso distinto de staging.
- Los errores no deben devolver tokens, identidad Access ni detalles internos.

## Criterios de aceptación

- solicitud anónima bloqueada antes de ejecutar el Worker;
- identidad autorizada aceptada;
- identidad no incluida denegada;
- todas las rutas y hostnames del Worker cubiertos;
- cero reglas Bypass;
- `api` y `sorteosdominicanos-app` fuera del alcance;
- eventos de autenticación visibles en logs Access.
