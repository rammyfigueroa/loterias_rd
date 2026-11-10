# Fase 10.3 - Correccion de rangos Android

## Diagnostico y causa

La prueba de widget que pulsa el boton real aplicaba correctamente el rango
antes de modificar el codigo. Ademas, un rechazo del validador muestra un
mensaje; el estado observado en el Pixel permanecio sin mensaje y como `Rango
pendiente de aplicar`. Esa evidencia indica que los toques automatizados ADB no
invocaron el handler y no demuestra un fallo del boton ni del recalculo.

La auditoria si encontro una inconsistencia real relacionada: el selector de
fechas de Flutter entrega valores locales, mientras que la cobertura se
normaliza a UTC en `StatsPage`. El validador eliminaba la hora pero conservaba
la zona original. Esto podia comparar el mismo dia calendario como instantes
diferentes y rechazar un limite valido segun la zona del dispositivo.

## Correccion

`StatisticsDateRangeValidator` normaliza ahora Desde, Hasta, hoy y los limites
de cobertura con `DateTime.utc(year, month, day)`. La comparacion queda basada
en el dia calendario y no en el desplazamiento horario.

No se modificaron formulas, endpoints, cache, repositorios ni infraestructura.
Un rango valido se aplica localmente sobre los resultados ya cargados. Si no
contiene resultados, conserva el periodo aplicado y muestra el estado vacio.

## Pruebas

Se agregaron pruebas para:

- fechas locales del selector contra limites UTC de cobertura;
- el rango real `01/11/2026` a `09/11/2026`;
- pulsar el boton `Aplicar fechas`;
- actualizar el periodo y el tamano de muestra.

La suite existente mantiene cobertura para rangos incompletos, invertidos,
futuros, fuera de cobertura, fechas inexistentes, estados vacios, errores,
reintentos, cache de sesion y calendario dominicano.

## Coincidencias de Primera

La entrada depende de estos valores de compilacion:

- `FIRST_PRIZE_STATS_ENABLED=true`;
- `FIRST_PRIZE_STATS_API_URL=<base publica verificada>`.

El Worker publico `https://api.sorteosdominicanos.workers.dev` responde en
`/health`, pero el endpoint `/statistics/first-prize/intervals` responde 404.
El staging existente esta protegido por Cloudflare Access y no debe conectarse
a una aplicacion publica ni recibir credenciales administrativas.

Recomendacion: mantener Coincidencias de Primera oculta en la proxima
compilacion Android hasta desplegar y verificar un endpoint publico de solo
lectura. No deben agregarse los `dart-define` anteriores mientras falte ese
requisito.

Las banderas `dreamsNumbersEnabled` y `historicalRelationsEnabled` permanecen
desactivadas.
