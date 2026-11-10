# Plan del repositorio HTTP futuro

Fecha: 2026-11-09.

## Componentes propuestos

```text
HistoricalRelationsApiConfig
  -> HistoricalRelationsRemoteSource
  -> RemoteHistoricalRelationsRepository
  -> HistoricalRelationsController existente
  -> HistoricalRelationsPage existente
```

No se implementa ninguno en esta fase.

## Configuración

`HistoricalRelationsApiConfig` debe recibir una base URL pública mediante
`--dart-define`, separada de staging y de Coincidencias de Primera. La función
solo estará disponible si la bandera y una configuración pública validada están
presentes. No debe incluir headers Access, tokens o cookies.

## Cliente

`HistoricalRelationsRemoteSource` debe:

- recibir `http.Client` inyectable;
- construir `Uri` con `queryParameters`;
- usar únicamente HTTPS;
- aplicar timeout explícito;
- aceptar solo HTTP 200 para datos;
- clasificar 400, 401/403, 404, 429 y 5xx;
- limitar tamaño de respuesta antes de decodificar cuando sea viable;
- decodificar JSON con parser estricto;
- cerrar únicamente clientes que él mismo haya creado.

## Serialización

Crear modelos remotos o factories que representen el contrato completo de
`99_contrato_flutter_worker.md`. El dominio no debe depender de mapas JSON.
Las advertencias se conservan como objetos con código, mensaje y detalle seguro.

## Paginación

El repositorio solicitará páginas secuenciales con un límite acotado. Debe:

1. conservar filtros idénticos en cada página;
2. enviar solo el cursor devuelto;
3. comprobar fingerprint constante;
4. detectar cursor repetido;
5. imponer máximo de páginas/resultados;
6. combinar y ordenar por conteo descendente y número ascendente;
7. no presentar datos parciales como completos si una página falla.

## Caché

Clave: operador, sorteo, posición, número, Desde, Hasta y cobertura. La entrada
debe incluir fingerprint, instante y respuesta completa. Propuesta:

- capacidad LRU acotada;
- TTL corto configurable;
- invalidación al cambiar fingerprint;
- caché no persistente inicialmente;
- no reutilizar respuesta sintética cuando se seleccione repositorio remoto;
- método explícito para limpiar caché en pruebas y actualización manual.

## Reintentos

Permitir como máximo un reintento para GET ante timeout, error de transporte,
`429` respetando `Retry-After`, o `5xx` seleccionado. No reintentar `400`,
`401`, `403`, `404` ni contrato inválido. Cancelación lógica y `requestId` del
controlador siguen siendo obligatorios aunque `package:http` no cancele una
solicitud ya enviada.

## Errores de dominio

Proponer clases estables:

- `HistoricalRelationsConfigurationException`;
- `HistoricalRelationsNetworkException`;
- `HistoricalRelationsTimeoutException`;
- `HistoricalRelationsApiException` con categoría, no cuerpo crudo;
- `HistoricalRelationsContractException`;
- `HistoricalRelationsPaginationException`.

La presentación traduce categorías a mensajes breves y permite reintento solo
cuando corresponde.

## Pruebas diseñadas

1. URI y parámetros exactos.
2. JSON completo válido.
3. campos opcionales y cobertura incompleta.
4. tipos, números, fechas y frecuencias inválidos.
5. clasificación de códigos HTTP.
6. timeout y error de transporte.
7. una y múltiples páginas.
8. cursor repetido y fingerprint cambiado.
9. caché hit, expiración, capacidad e invalidación.
10. filtros y series aislados.
11. respuesta tardía ignorada.
12. ausencia de headers Access, cookies y secretos.
13. build normal con bandera desactivada.
14. rechazo de fixture o hostname de staging en configuración pública.
15. lenguaje, cobertura y tamaño de muestra visibles.
