# Pruebas de integración de transiciones

Fecha: 2026-11-09.

## D1 local

`test/number-transitions-integration.test.js` utiliza `getPlatformProxy` de la
versión de Wrangler ya instalada, con `persist: false` y bindings remotos
desactivados. Aplica las migraciones existentes a una D1 efímera y carga solo
fixtures sintéticos.

No usa D1 de producción, no modifica `.wrangler/state` persistente y no instala
dependencias.

## Casos cubiertos

Las 21 pruebas comprueban:

1. registro de ruta;
2. binding D1 ausente;
3. IDs obligatorios;
4. serie no autorizada;
5. posición obligatoria;
6. números fuera del formato `00`–`99`;
7. fechas inválidas y rangos invertidos;
8. fecha futura según Santo Domingo;
9. rango fuera de cobertura;
10. determinismo con D1;
11. `NO_DRAW_SCHEDULED` verificado;
12. origen inexistente;
13. aislamiento entre series;
14. rangos solicitado, efectivo y disponible;
15. cobertura incompleta;
16. rechazo de `NO_DRAW_SCHEDULED` sin evidencia;
17. acierto de caché con la misma huella;
18. invalidación por corrección y revisión;
19. paginación ligada a revisión;
20. cobertura y cursores inválidos;
21. ausencia de lenguaje predictivo.

Duplicados equivalentes, conflictos de identidad/fecha, corrección canónica y
modos de cobertura permanecen cubiertos por las 26 pruebas del motor puro. Las
restricciones `UNIQUE` de D1 complementan esas defensas.

## Resultados

```text
node --test test/number-transitions-integration.test.js
21 aprobadas, 0 fallidas

node --test test/number-transitions.test.js
26 aprobadas, 0 fallidas

npm test
84 aprobadas, 0 fallidas
```

La suite completa conserva las 63 pruebas anteriores y añade 21 de integración.

## Advertencia de entorno

Wrangler emite una advertencia deprecada de Node para `punycode`. No es un fallo
de la implementación ni altera resultados. No se modificaron dependencias para
silenciarla.
