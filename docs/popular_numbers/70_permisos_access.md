# Permisos para Cloudflare Access

Fecha: 2026-11-09.

## Navegador

La sesión oficial del navegador tiene acceso a la cuenta correcta y una política
de `Super Administrator - All Privileges` para toda la cuenta. Puede acceder a:

- Zero Trust Overview;
- Access controls;
- Applications;
- Policies;
- Service credentials;
- Access settings;
- administración de miembros y políticas de permisos.

La posibilidad de navegar esas secciones no significa que Zero Trust ya esté
configurado. Actualmente todas las secciones Access dependen del onboarding.

## Wrangler

La sesión OAuth de Wrangler incluye permisos de cuenta, Workers y D1, pero no
anuncia `Access: Apps and Policies Read` ni `Access: Apps and Policies Write`.
Por ello Wrangler no es el mecanismo apropiado para configurar Access en el
estado actual.

No es necesario ampliar Wrangler para completar una configuración manual desde
el panel. Mantener separados ambos canales reduce el alcance del OAuth usado por
la CLI.

## Acciones que requieren autorización adicional

1. Completar `Get started` y crear/configurar la organización Zero Trust.
2. Elegir o aceptar cualquier plan, término o nombre de equipo.
3. Configurar un proveedor de identidad o One-time PIN.
4. Crear una aplicación Access para el Worker staging.
5. Crear políticas `Allow`, `Service Auth` o cualquier otra regla.
6. Crear service tokens o secretos.
7. Desplegar el Worker staging.
8. Habilitar `workers.dev`, preview, ruta o Custom Domain.

No se recomienda ampliar automáticamente los permisos OAuth de Wrangler ni
generar API tokens. Para la siguiente fase, el panel con la sesión administrativa
existente es el método de menor alcance.

## Seguridad prevista

Después del onboarding, la aplicación deberá proteger el Worker completo con
denegación predeterminada, una lista explícita de identidades autorizadas y cero
reglas Bypass. La configuración debe completarse mientras el Worker continúe sin
ingress público.
