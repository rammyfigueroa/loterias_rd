# Formulario de Zero Trust Free

Fecha: 2026-11-09.

## Alcance

Se inspeccionó en modo de solo lectura el checkout oficial de Zero Trust para la
cuenta `f171b568e3a3a203a09ef2fd6e337a2c`.

No se introdujeron datos, no se abrió un flujo externo de pago, no se marcaron
casillas y no se pulsó el botón final.

## Plan y resumen

El formulario muestra:

- producto: `Zero Trust Free`;
- precio del plan: `Free`;
- vencimiento mostrado: `$0/month`;
- capacidad incluida: hasta 50 usuarios;
- complementos adicionales: ninguno visible ni seleccionado;
- botón final: `Activate Zero Trust Free`.

No se mostró un impuesto calculado ni un total superior a cero. El formulario
indica que el cargo base actual es cero, pero advierte que el uso que exceda los
límites gratuitos puede facturarse mensualmente.

## Métodos de pago visibles

El checkout ofrece integraciones oficiales para:

- tarjeta mediante Stripe;
- Stripe Link;
- PayPal;
- Apple Pay;
- Google Pay.

No se inició ninguno de estos métodos. La opción `Pay without Link` permite usar
el formulario normal de pago en lugar de Stripe Link; no significa continuar
sin método de pago.

## Campos de facturación

Campos visibles sin indicador `optional`:

- nombre;
- apellido;
- país;
- dirección, línea 1;
- ciudad;
- estado o provincia;
- código postal;
- tipo de cuenta.

Estos campos se presentan como parte principal del perfil de facturación. Como
el formulario no se envió, no se provocó la validación y no se afirma que todos
sean obligatorios para cada país. Estado/provincia y código postal pueden
depender de la jurisdicción seleccionada.

Campos marcados expresamente como opcionales:

- dirección, línea 2;
- nombre de la organización de facturación;
- VAT/GST.

Los datos de tarjeta se encuentran dentro de un componente seguro del proveedor
de pago. No se inspeccionaron ni registraron datos financieros existentes.

## Condiciones

Antes del botón final aparecen dos casillas sin marcar:

1. aceptación de los Términos de Servicio y la Política de Privacidad;
2. autorización para cobrar mensualmente el uso que exceda los límites
   gratuitos hasta la cancelación.

La segunda condición indica que la cancelación surte efecto al final del período
de facturación vigente. No se aceptó ninguna condición.

## Costos y renovación

- Cargo base mostrado: `$0/month`.
- Cargo mostrado para el día de la inspección: `$0`.
- Impuestos mostrados: ninguno calculado.
- Renovación: el texto del checkout describe un ciclo mensual.
- Cargos potenciales: uso que exceda las prestaciones incluidas en Free.
- Servicios adicionales: ninguno visible ni seleccionado.

La ausencia de un impuesto calculado no garantiza que nunca se aplique uno; el
formulario solicita país y tipo de cuenta para determinar el tratamiento de
facturación aplicable.

## Alternativa sin método de pago

No existe una opción visible y oficial para omitir el método de pago. La
documentación de Cloudflare establece que el onboarding requiere seleccionar un
plan e introducir detalles de pago incluso para Zero Trust Free, aclarando que
el plan Free no genera el cargo base.

`Pay without Link`, Apple Pay, Google Pay y PayPal son alternativas de método de
pago, no excepciones al checkout.

Referencias oficiales:

- https://developers.cloudflare.com/cloudflare-one/setup/
- https://developers.cloudflare.com/cloudflare-one/faq/getting-started-faq/
- https://developers.cloudflare.com/billing/get-started/create-billing-profile/
- https://developers.cloudflare.com/billing/

## Nombre de la organización

El campo `Organization name (optional)` pertenece al perfil de facturación. No
es el `team name` que determina el dominio
`<team-name>.cloudflareaccess.com`.

El checkout actual no muestra un campo para configurar `sorteosdominicanos` como
team name. La documentación oficial coloca la elección del team name antes de
seleccionar el plan y completar el pago. Sin embargo, ese paso no quedó visible
ni confirmado en el estado actual del panel.

Por tanto:

- `sorteosdominicanos` no fue introducido ni reservado;
- su disponibilidad no fue comprobada;
- no se puede confirmar mediante este checkout si el panel volverá a solicitar
  el team name después de la activación;
- resolver esa diferencia exigiría avanzar el flujo, acción no autorizada en
  esta fase.

## Próxima acción manual

Una persona debe revisar y, si decide continuar, proporcionar el método y los
datos de facturación, aceptar conscientemente ambas condiciones y verificar el
team name antes de pulsar `Activate Zero Trust Free`.

Ese paso puede activar una suscripción y autorizar cargos por excedentes, por lo
que queda fuera de esta fase.
