# Auditoría de integración Flutter y Worker

Fecha: 2026-11-09.

## Alcance

Esta auditoría describe la conexión futura de Relaciones Históricas. No añade
HTTP, no modifica Flutter, Worker, D1, Access o producción y no activa ninguna
bandera.

## Flutter actual

La aplicación ya contiene dos patrones remotos:

1. `LotteryResultsRemoteSource` usa `package:http`, una URL definida mediante
   `LOTTERIES_API_URL`, valida HTTP 200 y decodifica JSON. No inyecta cliente,
   no aplica timeout y no distingue errores de transporte, contrato o servidor.
2. `FirstPrizeStatisticsRemoteSource` recibe `baseUrl` y `http.Client`, compone
   parámetros estructurados y consume todas las páginas. Su repositorio mantiene
   cachés en memoria por filtros, pero sin límite, TTL o invalidación por
   revisión.

Relaciones Históricas ya separa contrato de repositorio, controlador y UI. El
repositorio activo es `LocalHistoricalRelationsRepository`; el controlador
limpia la respuesta anterior y usa un `requestId` para descartar respuestas
tardías. Esos límites deben conservarse.

## Worker actual

`GET /statistics/number-transitions`:

- requiere `HISTORY_DB`;
- acepta exclusivamente series autorizadas por `operatorId` y `drawId`;
- exige `position=first` y número `00`–`99`;
- valida rango, fecha dominicana, cobertura, límite y cursor;
- usa consultas D1 parametrizadas;
- calcula fingerprint con resultados, cobertura y revisiones;
- mantiene caché LRU de 100 entradas;
- liga cada cursor al fingerprint;
- devuelve errores de validación sin detalle interno;
- responde con CORS abierto.

El endpoint implementado en staging depende de D1. El Worker público real
`api`, según la última auditoría remota documentada, no tenía binding D1. El
`wrangler.toml` genérico del checkout usa un UUID cero de marcador y el nombre
`loterias-rd-api`; no demuestra la configuración del Worker `api`.

## Entornos

### Staging

- Worker: `sorteosdominicanos-api-staging`.
- D1: `sorteosdominicanos-db-staging`.
- Entrada: una URL `workers.dev` protegida por Access para todo el tráfico.
- Datos: exclusivamente sintéticos.
- Acceso: una identidad administrativa exacta.

Staging no debe convertirse en backend móvil ni compartir credenciales con la
aplicación.

### Producción

- Worker público identificado: `api`.
- Endpoint de resultados: existente.
- Binding histórico D1: no identificado en la última auditoría.
- Datos históricos reales para transiciones: no demostrados.

No puede asumirse que desplegar el código local sobre `api` sea seguro o que
exista una D1 de producción compatible.

## Componentes reutilizables

- `StatisticsDrawOption` y sus IDs estructurados.
- `StatisticsDateRange` y fechas ISO.
- interfaz `HistoricalRelationsRepository`.
- controlador y protección frente a respuestas tardías.
- estados loading/data/empty/error.
- controles Desde/Hasta y cobertura.
- patrón de cliente inyectable de Coincidencias de Primera.
- validación, paginación y fingerprint del Worker.

## Componentes que no deben reutilizarse sin cambios

- acceso administrativo de Cloudflare Access;
- URL de staging como base URL móvil;
- cachés Flutter sin capacidad/TTL;
- `LotteryResultsRemoteSource` sin timeout ni cliente inyectable;
- rutas administrativas del Worker;
- UUID marcador de `wrangler.toml`.

## Bloqueos

1. No existe un inventario aprobado de historial real publicable.
2. No existe binding D1 histórico confirmado en producción.
3. No existe superficie pública de solo lectura aprobada.
4. Flutter todavía no puede deserializar el contrato completo.
5. No se ha definido política de rate limiting, caché HTTP u observabilidad.
6. La feature flag debe permanecer desactivada.
