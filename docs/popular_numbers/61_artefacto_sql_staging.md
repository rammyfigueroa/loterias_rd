# Artefacto SQL sintético para staging

Fecha: 2026-11-09.

## Archivo

`loterias_rd_api/fixtures/staging/base-fixture-v1.sql`

Propiedades:

- tamaño: 25,733 bytes;
- líneas: 854;
- resultados: 16;
- cobertura: 19;
- revisiones: 1;
- fixture de rendimiento: no incluido;
- datos reales o personales: ninguno.

SHA-256:

```text
8e416f716e10394ff4cf6629b0ec52afdcbd1b8e14d2a92213fdcbe56ecc3583
```

## Generación determinista

El artefacto se genera mediante:

```sh
npm run fixtures:staging:sql:generate
```

`scripts/generate-staging-fixture-sql.js` reutiliza directamente
`createBaseFixture()`. Una prueba compara byte por byte el archivo guardado con
una generación nueva. No utiliza reloj, aleatoriedad ni datos externos.

## Estrategia SQL

Cada resultado usa `INSERT ... SELECT ... WHERE NOT EXISTS` y comprueba tanto
`provider_result_id` como sorteo/fecha. Cobertura comprueba sorteo/fecha. La
revisión exige que el resultado canónico coincida con sorteo, fecha, número,
fuente, checksum y payload antes de insertarse.

No contiene:

- `UPDATE`;
- `DELETE`;
- `REPLACE`;
- `DROP`;
- `TRUNCATE`;
- `ALTER`;
- inserciones de operadores o sorteos.

El artefacto evita sobrescribir filas. Una colisión hace que esa fila no se
inserte; la verificación posterior obligatoria debe detectar que el conjunto no
coincide con el fixture. No debe interpretarse una ejecución SQL exitosa como
validación suficiente.

## Validación local

Se creó una D1 efímera con las migraciones 0001 y 0002.

Primera aplicación:

- resultados: 16;
- cobertura: 19;
- revisiones: 1;
- claves foráneas: correctas.

Segunda aplicación:

- conteos sin cambios: 16/19/1;
- duplicados: 0.

Análisis del origen `24`:

- `67`: 3, frecuencia 0.6;
- `24`: 1, frecuencia 0.2;
- `32`: 1, frecuencia 0.2;
- total: 5.

La prueba de colisión insertó previamente un resultado ajeno con número `99`.
El artefacto no lo modificó ni lo reemplazó.

## Restricción de uso

El archivo no fue ejecutado contra Cloudflare. Su existencia no autoriza una
carga remota. Antes de utilizarlo deben repetirse dry run, hash, revisión humana
y autorización limitada de una fase posterior.
