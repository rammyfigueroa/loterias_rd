# Seguridad del cargador remoto de fixtures

Fecha: 2026-11-09.

## Protección de dry run

El modo predeterminado y `--dry-run` son equivalentes. Ambos ejecutan únicamente:

- `wrangler whoami --json`;
- `wrangler d1 list --json`;
- `wrangler d1 execute ... --remote --json --command` con consultas que
  comienzan estrictamente por `SELECT` o `PRAGMA`.

El constructor vuelve a validar cada consulta antes de entregarla a Wrangler.
No existe una función de aplicación, un flag oculto ni un comando npm de
escritura.

## Validación del destino

La configuración debe coincidir exactamente con:

- `name = sorteosdominicanos-api-staging`;
- cuenta autorizada;
- una sola D1;
- `binding = HISTORY_DB`;
- nombre y UUID autorizados;
- `migrations_dir = migrations`;
- `ENVIRONMENT = staging`;
- `workers_dev = false`;
- `preview_urls = false`;
- ausencia de rutas.

La sesión Wrangler debe incluir la cuenta exacta. El inventario remoto debe
contener el UUID exacto asociado al nombre exacto. No se permite indicar `api`,
otra base o una configuración desde argumentos.

## Validación del esquema

Objetos funcionales requeridos:

- seis tablas históricas;
- seis índices explícitos;
- migraciones 0001 y 0002 aplicadas y ninguna adicional;
- operador Nacional;
- sorteos Gana Más y Lotería Nacional con IDs estructurados;
- `first_position_path = score[0][0]`;
- ambos sorteos habilitados;
- cero violaciones de claves foráneas.

Se toleran únicamente tablas internas conocidas de SQLite/D1. Cualquier otro
objeto funcional bloquea el plan.

## Idempotencia y colisiones

El auditor obtiene todas las filas de resultados, cobertura, revisiones y
backfill porque staging debe contener solo metadatos o el fixture sintético
exacto. Cada fila se compara campo por campo con `createBaseFixture()`.

- Cero filas: estado `EMPTY`.
- 36 filas exactas: estado `ALREADY_APPLIED`.
- Cualquier subconjunto: error de carga parcial.
- Cualquier identidad o campo diferente: colisión y detención.
- Cualquier backfill: detención.

No se considera que un prefijo sintético por sí solo autorice una fila.

## Atomicidad y recuperación

El dry run es de solo lectura y no necesita una transacción de escritura. Para
una fase futura:

- no se debe asumir que varios comandos Wrangler forman una transacción;
- una caída de red puede dejar resultado remoto ambiguo;
- una ejecución por archivo puede completar solo parte del trabajo según el
  comportamiento del servicio y del cliente;
- no debe improvisarse un rollback con borrados;
- después de cualquier error se debe repetir únicamente la inspección;
- el estado parcial debe quedar bloqueado hasta una autorización de recuperación;
- la recuperación debe comparar todas las filas antes de insertar faltantes;
- las restricciones únicas y claves foráneas son defensa adicional, no sustituto
  del preflight.

D1 ofrece operaciones por lote mediante bindings, pero no existe un Worker de
staging desplegado. La decisión entre un artefacto Wrangler revisado y un
mecanismo transaccional separado corresponde a 8.5B-7B.

## Criterios de detención

Detener sin escribir ante cualquier diferencia de cuenta, configuración,
migración, esquema, identidad, contenido, integridad o estado de producción.
También detener si el artefacto propuesto incluye el fixture de 5,000 eventos,
datos reales, operadores/sorteos o comandos de despliegue/backfill.
