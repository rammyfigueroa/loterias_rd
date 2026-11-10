# Carga remota controlada del fixture básico

Fecha: 2026-11-09.

## Destino autorizado

- Cuenta: `f171b568e3a3a203a09ef2fd6e337a2c`.
- D1: `sorteosdominicanos-db-staging`.
- UUID: `f31aac48-f437-4fd7-9691-a7e976010dc6`.
- Binding: `HISTORY_DB`.
- Configuración: `loterias_rd_api/wrangler.staging.toml`.

## Artefacto autorizado

- Archivo: `loterias_rd_api/fixtures/staging/base-fixture-v1.sql`.
- SHA-256:
  `8e416f716e10394ff4cf6629b0ec52afdcbd1b8e14d2a92213fdcbe56ecc3583`.
- Contenido: 16 resultados, 19 coberturas y 1 revisión.
- Fixture de rendimiento: excluido.
- Operaciones destructivas: ninguna.

## Verificación previa

Wrangler 4.155.0 confirmó la sesión OAuth y la cuenta autorizada. La base
enumerada coincidió por nombre y UUID. El dry run inmediatamente anterior a la
carga devolvió `EMPTY`, con cero resultados, coberturas y revisiones. Las
migraciones `0001_gana_mas_history.sql` y `0002_national_history.sql`, el
esquema y las identidades fueron validados por el cargador de solo lectura.

## Única carga remota

Se ejecutó una sola vez:

```sh
npx wrangler d1 execute sorteosdominicanos-db-staging \
  --remote \
  --file fixtures/staging/base-fixture-v1.sql \
  --config wrangler.staging.toml
```

Wrangler informó `success: true`, 36 consultas procesadas y 36 consultas
ejecutadas. No se repitió el comando.

## Verificación posterior

Las consultas posteriores fueron exclusivamente `SELECT` y `PRAGMA`:

- resultados: 16;
- coberturas: 19;
- revisiones: 1;
- `PRAGMA foreign_key_check`: sin filas;
- migraciones: 0001 y 0002 intactas;
- operador: Nacional;
- sorteos: Lotería Nacional y Gana Más;
- registros inesperados: ninguno;
- dry run posterior: `ALREADY_APPLIED`.

## Validación estadística

Para el número origen 24 de Gana Más se verificaron directamente en D1 cinco
transiciones válidas:

| Número siguiente | Conteo | Frecuencia relativa |
| --- | ---: | ---: |
| 67 | 3 | 0.600000 |
| 24 | 1 | 0.200000 |
| 32 | 1 | 0.200000 |

## Aislamiento

La única escritura remota fue el archivo autorizado contra la D1 staging. No
se ejecutaron despliegues, migraciones, backfills ni comandos dirigidos al
Worker `api`, a `sorteosdominicanos-app`, a DNS, Access, secretos o producción.
