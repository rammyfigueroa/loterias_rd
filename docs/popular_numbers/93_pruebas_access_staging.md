# Pruebas de Access en staging

Fecha: 2026-11-09.

## Prueba anónima

Se consultaron `/health` y `/statistics/number-transitions` sin autenticación.

Resultado en ambos casos:

- estado: `HTTP 302`;
- destino: inicio de sesión de Cloudflare Access;
- encabezado: `WWW-Authenticate: Cloudflare-Access`;
- respuesta del Worker: ausente;
- fuga de datos del fixture: ninguna.

El criterio de seguridad fue satisfactorio y no fue necesario revertir la URL.

## Prueba administrativa de salud

Después de iniciar sesión mediante el flujo oficial de Cloudflare Access:

- ruta: `GET /health`;
- `ok`: `true`;
- servicio: `loterias-rd-api`.

No se registraron ni exportaron cookies, tokens o credenciales.

## Prueba estadística

La consulta utilizó exclusivamente la serie sintética autorizada:

- operador: Nacional;
- sorteo: Gana Más;
- posición: `first`;
- número origen: `24`;
- cobertura: `verified`;
- rango efectivo: `2026-04-01` a `2026-04-11`.

Respuesta observada:

| Número siguiente | Transiciones | Frecuencia relativa |
| --- | ---: | ---: |
| `67` | 3 | 0.6 |
| `24` | 1 | 0.2 |
| `32` | 1 | 0.2 |

Total de transiciones: 5.

La respuesta identificó la serie exacta, informó cobertura `VERIFIED` y
conservó el descargo que indica que el análisis histórico no predice resultados
futuros.

## D1

La validación posterior de solo lectura devolvió:

- 16 resultados sintéticos;
- 19 registros de cobertura;
- 1 revisión;
- estado `ALREADY_APPLIED`;
- `writesExecuted: false`;
- `applyEnabled: false`.

No se ejecutaron backfill, fixtures, migraciones ni escrituras.
