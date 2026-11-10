# Selección controlada de Zero Trust Free

Fecha: 2026-11-09.

## Verificación previa

- Cuenta: `f171b568e3a3a203a09ef2fd6e337a2c`.
- Pantalla: `Choose a plan` del onboarding oficial.
- Plan: `Zero Trust Free`.
- Precio: `$0 / seat / month`.
- Límite: 50 asientos.
- Complementos seleccionados: ninguno.

## Selección realizada

Se pulsó exclusivamente `Select plan` en la tarjeta de Zero Trust Free. No se
seleccionaron Standard, Enterprise ni complementos.

La selección abrió directamente:

```text
/zero-trust/checkout/payment
```

Esto confirma que Cloudflare exige pasar por una etapa de pago/facturación aun
para Free. La selección abrió el checkout, pero no creó una suscripción ni una
organización.

## Pantalla posterior

La pantalla de pago permaneció en estado `Loading`. Se realizó una única recarga
de lectura y continuó igual. No aparecieron campos utilizables de:

- tarjeta o método de pago;
- dirección de facturación;
- titular;
- nombre de organización;
- team name o dominio de autenticación;
- aceptación de términos;
- botón final de compra o creación.

No se intentó desactivar extensiones, cambiar la sesión o usar otra vía para
forzar el formulario.

## Nombre propuesto

El campo de organización no llegó a mostrarse. Por tanto:

- nombre propuesto: `sorteosdominicanos`;
- disponibilidad: no comprobada;
- dominio esperado: `sorteosdominicanos.cloudflareaccess.com`;
- sustitución automática: no realizada.

## Verificación posterior

Después de abandonar el checkout y volver a Zero Trust Overview, el panel siguió
mostrando `Welcome to Cloudflare Zero Trust` y `Get started`. Esto confirma:

- organización Zero Trust no creada;
- onboarding no completado;
- aplicación y políticas Access no creadas;
- plan Free no activado como suscripción;
- ausencia de cargos confirmados.

## Bloqueo

El siguiente paso requiere que el formulario de pago cargue correctamente y que
una persona revise los campos financieros. Introducir información de pago o
pulsar una confirmación final requiere autorización independiente y no forma
parte de esta fase.
