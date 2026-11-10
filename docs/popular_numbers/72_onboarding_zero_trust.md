# Onboarding de Cloudflare Zero Trust

Fecha: 2026-11-09.

## Estado inspeccionado

La sesión administrativa abrió el onboarding oficial de la cuenta
`f171b568e3a3a203a09ef2fd6e337a2c`. La primera pantalla es `Choose a plan`.
No se seleccionó ningún plan ni se envió ningún formulario.

## Pantalla de planes

### Zero Trust Free

- precio mostrado: `$0 / seat / month`;
- límite: 50 asientos;
- orientado a laboratorios domésticos y pruebas de concepto;
- acceso remoto Zero Trust mediante agente o sin agente;
- filtrado DNS, red y HTTP;
- integraciones con proveedores de identidad y postura de dispositivo;
- dos integraciones API de CASB/SSPM;
- cinco pruebas Digital Experience Monitoring;
- retención de logs: 24 horas;
- acceso por API y Terraform;
- soporte por comunidad y documentación.

### Zero Trust Standard

- precio mostrado: `$7 / seat / month`;
- sin límite de asientos;
- retención de logs: 30 días;
- 30 pruebas Digital Experience Monitoring;
- notificaciones y alertas;
- 25 ubicaciones de filtrado DNS;
- Browser Isolation disponible como complemento;
- soporte mediante ticket, comunidad y documentación.

### Zero Trust Enterprise

- precio: personalizado;
- requiere contactar ventas;
- retención de 90 días y Logpush;
- integraciones CASB completas;
- perfiles DLP personalizados y otras capacidades empresariales;
- soporte empresarial.

## Pago y renovación

La documentación oficial indica que el onboarding solicita información de pago
incluso al elegir Free, aunque el plan Free no genera cobro. No se inspeccionó
ni completó esa pantalla porque hacerlo requiere primero seleccionar un plan.

Cloudflare permite cambiar o cancelar la suscripción. Una reducción de plan se
aplica en el siguiente ciclo; una ampliación puede facturarse al seleccionarla.
No se aceptó suscripción, renovación, término ni compromiso económico.

## Organización

Cloudflare requiere un `team name` único. Ese nombre se convierte en el dominio
de equipo:

```text
<team-name>.cloudflareaccess.com
```

Nombre propuesto:

```text
sorteosdominicanos
```

La disponibilidad no fue comprobada porque el campo aparece después de elegir
un plan. No debe usarse un nombre alternativo heredado sin nueva revisión.

## Identidad

Una organización nueva recibe automáticamente Cloudflare Identity como método
predeterminado. Esto permite autenticar miembros existentes de la cuenta.

Posteriormente pueden añadirse:

- One-time PIN para correos expresamente autorizados;
- proveedores externos OIDC, OAuth o SAML;
- otros proveedores sociales o corporativos compatibles;
- passkeys, si se aprueban en una fase posterior.

OTP ya no se añade automáticamente. Configurarlo, registrar identidades o enviar
códigos requiere autorización separada.

## Pantallas no recorridas

No se seleccionó `Select plan`; por tanto no se inspeccionaron directamente las
pantallas posteriores de team name, pago o confirmación. Sus requisitos se
documentan desde las guías oficiales, no como campos visualmente confirmados en
esta sesión.

## Fuentes oficiales

- [Get started with Cloudflare One](https://developers.cloudflare.com/cloudflare-one/setup/)
- [Zero Trust getting started FAQ](https://developers.cloudflare.com/cloudflare-one/faq/getting-started-faq/)
- [Identity providers](https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/)
- [One-time PIN](https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/one-time-pin/)
