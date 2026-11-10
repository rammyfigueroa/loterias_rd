# Team name de Zero Trust

Fecha: 2026-11-09.

## Alcance autorizado

Se actualizó exclusivamente el team name de Cloudflare Zero Trust en la cuenta
`f171b568e3a3a203a09ef2fd6e337a2c`.

No se modificaron facturación, proveedores de identidad, aplicaciones Access,
políticas, Workers, D1, producción, DNS ni secretos.

## Verificación previa

Antes del cambio, el panel confirmó:

- plan activo: `Zero Trust Free`;
- precio: `$0 / month`;
- team name: `bitter-flower-655f`;
- dominio: `bitter-flower-655f.cloudflareaccess.com`;
- aplicaciones Access observadas: ninguna;
- políticas Access reutilizables observadas: ninguna.

La sección de aplicaciones y la sección de políticas mostraban sus estados
iniciales, sin recursos configurados que dependieran del dominio anterior.

## Cambio realizado

En el editor oficial del team name se introdujo:

```text
sorteosdominicanos
```

Se pulsó `Save` una sola vez. Cloudflare mostró una confirmación indicando que
el team domain cambiaría a:

```text
sorteosdominicanos.cloudflareaccess.com
```

La confirmación fue aceptada dentro del alcance autorizado. Cloudflare no
mostró un error de disponibilidad ni propuso un nombre alternativo.

## Resultado confirmado

El panel final muestra:

- team name: `sorteosdominicanos`;
- dominio completo: `sorteosdominicanos.cloudflareaccess.com`;
- plan: `Zero Trust Free`;
- precio: `$0 / month`.

El cambio no creó aplicaciones ni políticas Access. No se observaron
dependencias configuradas que requirieran migración desde el dominio anterior.

## Recursos no modificados

- Facturación y método de pago.
- Proveedores de identidad.
- Aplicaciones Access.
- Políticas Access.
- Worker de producción `api`.
- Aplicación web `sorteosdominicanos-app`.
- Worker futuro `sorteosdominicanos-api-staging`.
- D1 `sorteosdominicanos-db-staging`.
- DNS, rutas y secretos.

## Próximo paso recomendado

En una fase posterior y con autorización independiente, crear la aplicación y
la política de Cloudflare Access que protegerán el Worker de staging. La
política debe conservar denegación predeterminada y no debe incluir reglas
`Bypass` ni acceso amplio.
