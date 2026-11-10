# Dry run remoto de fixtures

Fecha: 2026-11-09.

## Comando ejecutado

Desde `loterias_rd_api`:

```sh
npm run fixtures:staging:remote:dry-run
```

No se pasaron `--apply`, `--write` o `--yes`. El script ejecutó diez
inspecciones oficiales: identidad, inventario D1 y ocho consultas SQL que
comienzan por `SELECT` o `PRAGMA`.

## Destino confirmado

- Cuenta: `f171b568e3a3a203a09ef2fd6e337a2c`.
- D1: `sorteosdominicanos-db-staging`.
- UUID: `f31aac48-f437-4fd7-9691-a7e976010dc6`.
- Binding: `HISTORY_DB`.
- Configuración: `wrangler.staging.toml`.
- Worker futuro: `sorteosdominicanos-api-staging`.

La rama fue `production-access-ready` y HEAD
`cad662294e23b8cfc61aca5dfdf0d2dc0db919cc`. Los cambios previos del árbol de
trabajo fueron identificados y preservados.

## Compatibilidad real con Wrangler

Wrangler 4.155.0 devolvió JSON que el parser procesó sin adaptación:

- `whoami --json`: identidad de cuenta reconocida;
- `d1 list --json`: nombre y UUID exactos;
- `d1 execute --remote --json`: matrices de resultados compatibles con
  `resultRows()`;
- código de salida final: 0;
- errores JSON o respuestas ambiguas: ninguno.

La advertencia de deprecación `punycode` procede de Wrangler/Node y no afectó
la ejecución.

## Estado remoto

Resultado: `EMPTY`.

| Tipo | Existentes | Esperados | Faltantes |
| --- | ---: | ---: | ---: |
| Resultados | 0 | 16 | 16 |
| Cobertura | 0 | 19 | 19 |
| Revisiones | 0 | 1 | 1 |

También se confirmó:

- migraciones 0001 y 0002 aplicadas;
- seis tablas funcionales y seis índices explícitos;
- identidades estructuradas correctas;
- cero estados de backfill;
- cero violaciones de claves foráneas;
- fixture de rendimiento excluido;
- `writesExecuted: false`;
- `applyEnabled: false`.

## Resultado estadístico esperado

Para el origen `24`, después de una carga futura:

- `67`: 3 transiciones, frecuencia 0.600000;
- `24`: 1 transición, frecuencia 0.200000;
- `32`: 1 transición, frecuencia 0.200000;
- total: 5;
- última aparición sin sucesor: 1.

## Escrituras

No se ejecutaron inserciones, actualizaciones, eliminaciones, migraciones ni
despliegues. Todas las consultas remotas fueron de solo lectura.
