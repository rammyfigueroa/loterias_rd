# Carga local de fixtures sintéticos

Fecha: 2026-11-09.

## Script

El comando se define en `loterias_rd_api/package.json`:

```sh
npm run fixtures:staging:local -- --local --persist-to /tmp/sorteos-fixtures
```

Para incluir los 5,000 eventos de rendimiento:

```sh
npm run fixtures:staging:local -- --local --persist-to /tmp/sorteos-fixtures-performance --include-performance
```

El directorio debe ser local, explícito y externo al repositorio cuando se
quiera una ejecución efímera. No debe reutilizarse un directorio que contenga
datos ajenos.

## Bloqueos de seguridad

`load-staging-fixtures-local.js`:

1. exige `--local`;
2. exige `--persist-to`;
3. rechaza `--remote` y argumentos desconocidos;
4. usa `remoteBindings: false` y no carga archivos de variables de entorno;
5. valida nombre de Worker, cuenta, entorno, binding, base y UUID de staging;
6. exige `workers_dev = false`, `preview_urls = false` y ausencia de rutas;
7. verifica las seis tablas funcionales y las identidades estructuradas;
8. aplica 0001 y 0002 solo cuando la D1 local está completamente vacía;
9. rechaza un esquema parcial;
10. verifica conteos e integridad referencial después de cargar.

La configuración se lee mediante `unstable_readConfig` de Wrangler. El script
no analiza TOML manualmente y no implementa ninguna ruta de carga remota.

## Resultado observado

Se utilizó una persistencia efímera bajo:

```text
/tmp/sorteos-fixtures-local.ZG7mI4
```

Primera carga:

```text
resultados insertados: 16
cobertura insertada: 19
revisiones insertadas: 1
```

Segunda carga sobre la misma D1 local:

```text
resultados insertados: 0
cobertura insertada: 0
revisiones insertadas: 0
```

Los totales permanecieron en 16, 19 y 1. No se ejecutó ningún comando D1 con
`--remote`.

## Colisiones

Si un `provider_result_id`, sorteo/fecha, cobertura o revisión ya existe con
contenido distinto, el script termina con `Fixture collision` y no modifica la
fila ajena. La prueba de conflicto confirma que el valor extranjero se conserva
y que no se insertan filas de cobertura después de detectar el conflicto.

## Futuro uso remoto

Este script no debe adaptarse mediante un simple cambio de bandera. Una futura
carga en Cloudflare requiere otra fase que:

- autorice expresamente la D1 y el contenido;
- inspeccione que la base siga sin resultados inesperados;
- produzca un artefacto revisable o un script remoto separado;
- ejecute preflight completo antes de cualquier escritura;
- limite la operación al UUID autorizado;
- confirme conteos, fingerprints e integridad después de la carga;
- documente recuperación ante una ejecución parcial.

La presente fase no concede esa autorización.
