# Plan de pruebas de staging

Fecha: 2026-11-09.

## Objetivo

Validar `GET /statistics/number-transitions` en recursos remotos aislados y con
datos sintéticos controlados. Este documento no autoriza la creación de
recursos, migraciones, carga de datos ni despliegues.

## Plan de datos sintéticos

Preparar un fixture reproducible para las dos series estructuradas existentes,
sin copiar D1 de producción ni consultar proveedores externos:

- resultados canónicos con números `00`–`99`;
- identidades de proveedor sintéticas y claramente marcadas;
- rangos cortos y un rango de 5,000 eventos para rendimiento;
- cobertura `RESULT_FOUND` completa;
- `NO_DRAW_SCHEDULED` con `verification_source` sintética;
- días `UNVERIFIED`, `PENDING`, `NO_RESULTS_RETURNED` y `FETCH_FAILED`;
- una corrección canónica con fila en `result_revisions`;
- intentos controlados de duplicar `provider_result_id` y `draw_id/draw_date`;
- series con fechas solapadas para demostrar aislamiento.

La carga futura debe ejecutarse mediante un script revisable, idempotente y
limitado al ID confirmado del D1 de staging. Debe abortar si el nombre o ID no
coinciden con el manifiesto aprobado.

## Matriz de pruebas

1. Endpoint válido: respuesta 200, serie y origen exactos.
2. Parámetros inválidos: IDs, posición, número, cobertura, rango y cursor.
3. Serie inexistente o no autorizada: error de validación sin datos cruzados.
4. Cobertura verificada: continuidad solo con resultados o no-sorteos con
   evidencia.
5. Cobertura incompleta: advertencias y calidad conservadora.
6. Fechas futuras: rechazo según `America/Santo_Domingo`.
7. Límites dominicanos: fecha local distinta de UTC cerca de medianoche.
8. Correcciones: fila canónica actualizada y revisión registrada.
9. Fingerprint: cambia al corregir resultado o cobertura.
10. Caché: MISS inicial, HIT equivalente e invalidación por fingerprint.
11. Paginación: límites, cursor opaco y rechazo tras nueva revisión.
12. Rango largo: 5,000 eventos sintéticos sin mezclar series.
13. Latencia: separar total, D1 y motor.
14. Aislamiento: Worker, D1, IDs y datos diferentes de producción.
15. Errores: binding ausente, fallo D1 y ruta/método incorrectos.
16. Determinismo: mismo snapshot y parámetros producen el mismo contenido.
17. Ausencia de predicciones: respuesta y UI futura solo describen frecuencia
    histórica observada.

## Observabilidad propuesta

Añadir únicamente en una fase autorizada mediciones estructuradas por petición:

- ID de correlación no sensible;
- ruta, estado HTTP y serie estructurada;
- tiempo total, tiempo D1 y tiempo del motor;
- cantidad de resultados y filas de cobertura leídas;
- cantidad de transiciones y destinos devueltos;
- tamaño aproximado de respuesta;
- estado de caché;
- CPU reportada por la plataforma y errores/excepciones.

No registrar tokens, encabezados de autorización, payloads completos, raw HTML,
identificadores personales ni contenido de secretos. La memoria por petición no
está instrumentada actualmente; puede aproximarse con el benchmark sintético y
los límites/errores de plataforma, sin presentarla como medición exacta remota.

## Protocolo de ejecución futuro

1. Verificar cuenta, Worker, D1 e IDs contra el manifiesto aprobado.
2. Confirmar que no existen rutas, dominios ni cron.
3. Aplicar migraciones solo al D1 de staging.
4. Cargar fixtures sintéticos y verificar conteos/checksums.
5. Desplegar solo con `wrangler.staging.toml`.
6. Ejecutar pruebas funcionales y de seguridad.
7. Ejecutar carga gradual: 1, 10 y 50 solicitudes concurrentes controladas.
8. Capturar métricas sin contenido sensible.
9. Detener, preservar evidencia y no avanzar a Flutter/producción si falla un
   criterio.

## Criterios de aceptación

- IDs remotos de Worker y D1 confirmados y exclusivos de staging.
- Cero rutas, dominios o triggers de producción.
- Solo fixtures sintéticos; cero backfill y cero copia de producción.
- Todas las pruebas funcionales pasan y no hay mezcla de series.
- Restricciones de duplicados y revisiones se comportan como el esquema.
- Fingerprint, caché y paginación permanecen coherentes.
- Cero respuestas 5xx en la ejecución controlada.
- Resultado determinista para un snapshot inmutable.
- La prueba de 5,000 eventos no supera límites de plataforma ni muestra una
  degradación bloqueante respecto de la línea base local documentada.
- Ningún texto presenta frecuencias históricas como predicciones.

No se fija un SLA remoto antes de medir staging. Tras la primera ejecución debe
registrarse una línea base de p50/p95/p99 para total, D1 y motor y aprobarse
humanamente antes de producción.

## Criterios de detención

- ID de D1 desconocido, cero, compartido o no verificable.
- Cualquier ruta, dominio, trigger o binding que alcance producción.
- Worker público sin control de acceso aceptado.
- Aparición de datos reales no autorizados.
- Escritura fuera del D1 de staging.
- Mezcla de series, continuidad inferida desde cobertura desconocida o
  `NO_DRAW_SCHEDULED` sin evidencia.
- Fingerprint o caché obsoletos después de una corrección.
- Errores 5xx, pérdida de determinismo o límites de plataforma excedidos.
- Registro de secretos o datos sensibles.

## Comandos propuestos, no ejecutados

Tras creación y despliegue autorizados, las pruebas deben usar una URL de
staging aprobada y parámetros sintéticos. No se incluye token ni URL real en
este documento.

```sh
curl --fail --silent --show-error "https://STAGING_URL/health"
curl --fail --silent --show-error "https://STAGING_URL/statistics/number-transitions?operatorId=OPERATOR_ID&drawId=DRAW_ID&position=first&number=10&coverage=verified"
```
