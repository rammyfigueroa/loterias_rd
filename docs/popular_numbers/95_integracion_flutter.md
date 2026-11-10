# Integración Flutter de Relaciones Históricas

Fecha: 2026-11-09.

## Alcance

La Fase 8.6 incorpora una implementación Flutter local de **Relaciones
Históricas** dentro de Estadísticas. La función permanece oculta mediante
`AppFeatures.historicalRelationsEnabled = false` y no realiza solicitudes de
red.

La bandera preexistente `AppFeatures.dreamsNumbersEnabled` también permanece en
`false`.

## Arquitectura

El módulo vive en `lib/features/historical_relations/` y mantiene cuatro capas:

- `domain/historical_relations.dart`: consulta, cobertura, calidad, destinos y
  respuesta agregada;
- `data/historical_relations_repository.dart`: contrato de repositorio e
  implementación sintética local con caché;
- `application/historical_relations_controller.dart`: selección, rango,
  estados, errores y protección frente a respuestas tardías;
- `presentation/`: navegación protegida, tarjeta de entrada y pantalla.

Las identidades estructuradas de Lotería Nacional y Gana Más se reutilizan de
`StatisticsSeries`; no se duplican IDs ni se mezclan series.

## Modelos

`HistoricalRelationsQuery` conserva:

- operador y sorteo;
- posición conceptual `first` en la clave de caché;
- número origen;
- rango opcional inclusivo;
- cobertura `verified`, `incomplete` o `all`.

`HistoricalRelationsResult` contiene apariciones, total de transiciones,
calidad, destinos, conteos, frecuencia relativa, última fecha, advertencias y
descargo no predictivo. Los nombres siguen el contrato de
`GET /statistics/number-transitions`, pero esta fase no consume ese endpoint.

## Repositorio local

`LocalHistoricalRelationsRepository` utiliza exclusivamente datos sintéticos.
Para el número `24` devuelve de forma determinista:

| Destino | Conteo | Frecuencia observada |
| --- | ---: | ---: |
| `67` | 3 | 0.6 |
| `24` | 1 | 0.2 |
| `32` | 1 | 0.2 |

La caché incluye operador, sorteo, posición, número, Desde, Hasta y cobertura.
No existen `http`, URLs, cookies, tokens, secretos ni credenciales en el módulo.

## Controlador

El controlador implementa:

- estados `idle`, `loading`, `data`, `empty` y `error`;
- cambio independiente de serie, número y cobertura;
- fechas pendientes y rango aplicado;
- validación de rango incompleto o invertido;
- `Todo el historial`;
- contador de solicitudes para ignorar respuestas tardías;
- limpieza de la respuesta anterior al iniciar una carga.

## Interfaz

La pantalla incluye:

- selector de lotería y sorteo;
- selector de número `00`–`99`;
- selector de cobertura;
- `Desde`, `Hasta`, `Todo el historial` y `Aplicar fechas`;
- resumen de muestra y cobertura;
- destinos ordenados con conteo, frecuencia observada y última fecha;
- estados de carga, error y vacío;
- advertencia de cobertura incompleta;
- descargo que aclara que el análisis no predice resultados futuros.

Los controles de fecha se apilan por debajo de 420 dp. La pantalla fue validada
a 320 dp sin desbordamientos.

## Navegación

`StatsPage` solo construye `HistoricalRelationsEntry` cuando recibe la bandera
habilitada. `openHistoricalRelations` vuelve a comprobar la bandera antes de
abrir la ruta. En la compilación normal ambas barreras permanecen cerradas.

## Limitaciones

- Los datos son sintéticos y cubren deliberadamente una muestra pequeña.
- No hay paginación porque no existe consumo remoto.
- La caché vive en memoria durante la sesión.
- No se conecta a staging ni producción.
- No se modificaron Android, iOS, Worker, D1 o Cloudflare Access.
