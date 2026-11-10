# Fase 9.1 - Refresco no bloqueante y cache de sesion

## Alcance implementado

- Inicio y Estadisticas comparten una unica `LotteryResultsSession` para el recurso compatible `GET /results`.
- La primera carga conserva los estados de carga y error de pantalla completa.
- Los refrescos posteriores mantienen visibles los resultados y muestran un indicador discreto.
- Un error de red conserva la ultima respuesta valida, muestra un aviso breve y permite reintentar.
- Las solicitudes simultaneas al mismo recurso se deduplican.
- Una respuesta tardia invalidada no puede reemplazar datos mas recientes.

## Cache e invalidacion

La cache vive solamente durante la sesion de la aplicacion y tiene un TTL de cinco minutos. Una consulta dentro de ese periodo reutiliza la respuesta valida. Al expirar, la sesion solicita datos nuevos sin ocultar los anteriores.

`invalidate()` descarta la vigencia y protege contra respuestas anteriores. `invalidate(clearData: true)` tambien elimina los datos visibles y obliga a realizar una carga inicial nueva.

La cache no incluye ni combina:

- Endpoints de estadisticas historicas o de primer premio.
- Operadores o sorteos consultados mediante recursos distintos.
- Rangos de fechas, coberturas o revisiones independientes.
- Modulos experimentales.

## Actualizacion visible

La hora mostrada como ultima actualizacion se obtiene exclusivamente de `updatedAt` de la respuesta valida de la API y se presenta en hora dominicana. La hora interna de descarga solo controla el TTL y no se presenta como si fuera la frescura declarada por el servidor.

## Archivos principales

- `loterias_rd_app/lib/data/lottery_results_session.dart`
- `loterias_rd_app/lib/app/app.dart`
- `loterias_rd_app/lib/features/results/presentation/results_page.dart`
- `loterias_rd_app/lib/features/results/presentation/stats_page.dart`
- `loterias_rd_app/test/lottery_results_session_test.dart`

## Pruebas

Las pruebas usan un repositorio simulado sin acceso a Internet. Cubren primera carga, cache vigente y vencida, deduplicacion, refresco exitoso, error con datos anteriores, reintento, invalidacion, respuesta tardia, aislamiento entre sesiones y reutilizacion entre Inicio y Estadisticas.

## Limitaciones

- La cache es de memoria y se pierde al cerrar el proceso.
- No se persisten respuestas en disco.
- No se modificaron endpoints, infraestructura, configuracion nativa ni dependencias.
- `AppFeatures.historicalRelationsEnabled` y `AppFeatures.dreamsNumbersEnabled` permanecen desactivadas.
