# Plan de configuración de Zero Trust

Fecha: 2026-11-09.

## Recomendación de plan

Para la validación aislada del Worker staging, Zero Trust Free cubre el alcance
previsto: menos de 50 identidades, Access, integración de identidad y logs
básicos. No existe una necesidad técnica demostrada para Standard o Enterprise.

La selección final debe detenerse si el panel presenta precios, impuestos,
renovación o condiciones diferentes de los documentados en la pantalla inicial.

## Identidad propuesta

- Nombre de equipo preferido: `sorteosdominicanos`.
- Dominio esperado, sujeto a disponibilidad:
  `sorteosdominicanos.cloudflareaccess.com`.
- Método inicial recomendado: Cloudflare Identity, limitado a miembros
  autorizados de la cuenta.
- OTP: opcional y desactivado inicialmente.
- Proveedor externo: innecesario para la primera validación.

## Secuencia futura controlada

1. Autorizar expresamente la selección de Zero Trust Free.
2. Revisar los datos de pago solicitados sin introducirlos automáticamente.
3. Comprobar disponibilidad de `sorteosdominicanos`.
4. Revisar la pantalla final y todos los términos antes de crear la organización.
5. Crear la organización solo tras una confirmación humana en el último paso.
6. Verificar que Cloudflare Identity sea el único método inicial.
7. Mantener cero aplicaciones y políticas hasta una fase posterior.
8. Preparar la aplicación Access para el Worker staging con denegación
   predeterminada y Allow explícito.

## Política posterior

- destino: Worker completo `sorteosdominicanos-api-staging`;
- todo el tráfico protegido;
- sin `Everyone`;
- sin Bypass;
- sin dominio de correo amplio;
- identidades permitidas explícitas;
- `/internal/history/backfill` protegido además por su control interno;
- ningún alcance sobre `api` o `sorteosdominicanos-app`.

## Riesgos y criterios de detención

- plan o precio diferente;
- exigencia de un compromiso económico no revisado;
- team name no disponible;
- creación automática de una aplicación, política o Gateway no prevista;
- OTP o proveedor externo habilitado sin autorización;
- solicitud de ampliar OAuth de Wrangler;
- cualquier cambio sobre producción, DNS, Worker o D1.
