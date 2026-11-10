# Plan de carga remota de fixtures sintéticos

Fecha: 2026-11-09.

## Alcance

La Fase 8.5B-7A prepara una auditoría remota independiente para la futura carga
del fixture base. No implementa ni habilita escrituras remotas.

Destino único:

- cuenta: `f171b568e3a3a203a09ef2fd6e337a2c`;
- D1: `sorteosdominicanos-db-staging`;
- UUID: `f31aac48-f437-4fd7-9691-a7e976010dc6`;
- binding: `HISTORY_DB`;
- configuración: `loterias_rd_api/wrangler.staging.toml`;
- Worker futuro: `sorteosdominicanos-api-staging`.

No existe selección dinámica de cuenta, base, UUID, binding o configuración.
No se aceptan nombres aproximados ni configuraciones implícitas.

## Arquitectura

`loterias_rd_api/scripts/load-staging-fixtures-remote.js` es un proceso separado
del cargador local. Su única ruta ejecutable es `DRY_RUN`:

1. valida la configuración local explícita;
2. verifica que existan exactamente las migraciones 0001 y 0002;
3. construye comandos oficiales Wrangler de solo lectura;
4. comprueba sesión/cuenta e inventario D1;
5. inspecciona migraciones, esquema, identidades y datos;
6. compara filas existentes con el fixture base;
7. produce un informe sin ejecutar escrituras.

El script no contiene `INSERT`, `UPDATE`, `DELETE`, `REPLACE`, `DROP` o
`TRUNCATE`. `--apply`, `--write` y `--yes` se rechazan antes de cualquier
inspección.

## Fixture autorizado para el plan

- resultados: 16;
- cobertura: 19;
- revisiones: 1;
- fixture de rendimiento: excluido;
- operadores o sorteos nuevos: ninguno;
- resultados reales, tablas comerciales o datos personales: ninguno.

Se reutiliza `createBaseFixture()` y las identidades estables
`synthetic-staging-v1-*`. El plan rechaza cualquier fixture que no sea el base
o que contenga identidades de rendimiento.

## Estados del dry run

### `EMPTY`

No existen resultados, cobertura, revisiones o backfill. El informe muestra
16, 19 y 1 filas faltantes. Este estado no inserta nada.

### `ALREADY_APPLIED`

Las 36 filas coinciden campo por campo con el fixture validado. El informe
reconoce el estado idempotente y no propone duplicados.

### Bloqueado

El proceso termina sin éxito ante:

- carga parcial;
- fila ajena o diferente;
- migración pendiente, faltante o inesperada;
- tabla o índice faltante/inesperado;
- identidad estructurada diferente;
- estado de backfill;
- violación de clave foránea;
- cuenta, nombre o UUID distintos.

## Secuencia futura para 8.5B-7B

Comprobación previa de solo lectura:

```sh
cd loterias_rd_api
npm run fixtures:staging:remote:dry-run
```

La aplicación futura deberá crearse y revisarse en 8.5B-7B. No existe aún un
comando ejecutable de aplicación. Después de autorización, la fase deberá:

1. repetir el dry run y exigir estado `EMPTY`;
2. generar un archivo SQL exacto y revisable solo para el fixture base;
3. comparar hash y conteos del artefacto;
4. ejecutar Wrangler con nombre D1 y configuración explícitos;
5. verificar inmediatamente 16/19/1, integridad y transiciones;
6. repetir el dry run y exigir `ALREADY_APPLIED`;
7. comprobar que producción no cambió.

Un comando de escritura candidato, que **no fue creado ni ejecutado**, tendría
que mantener todos los destinos explícitos:

```sh
WRANGLER_SEND_METRICS=false npx --no-install wrangler d1 execute \
  sorteosdominicanos-db-staging \
  --remote \
  --config wrangler.staging.toml \
  --file /ruta/absoluta/al/artefacto-revisado.sql
```

Ese comando no debe usarse hasta que 8.5B-7B autorice el artefacto exacto.
