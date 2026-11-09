# Validación de la Fase 5.5

## Alcance

Se amplió `RightsEvidence`, el esquema JSON, el cargador, el validador y el
wrapper inmutable. No se modificaron Worker, D1, endpoints, dependencias,
configuración nativa ni funcionalidades ajenas al módulo.

## Compatibilidad

- Lectura permitida: esquemas 1.0, 1.1 y 1.2.
- Publicación: solo esquema 1.2 con `legalBasisType` válido.
- No existe migración silenciosa.
- Los catálogos anteriores no reciben autorización automática.

## Pruebas incorporadas

Fixtures sintéticos positivos para `explicitPermission`, `originalWork`,
`compatibleOpenLicense` y `reviewedLegalException`. Casos negativos para permiso
sin documento, obra original sin autoría, licencia sin condiciones, excepción
sin revisión, derechos desconocidos y catálogo 1.1 en el gate. También se
comprueba la inmutabilidad de las nuevas colecciones.

## Resultados

- `flutter test`: 125 de 125 pruebas aprobadas.
- Análisis aislado de `lib/features/dreams_numbers` y sus pruebas: sin
  problemas.
- `flutter analyze` global: 53 avisos preexistentes fuera del alcance de esta
  fase; no se introdujeron errores en el módulo.
- `git diff --check`: sin errores en archivos rastreados ni en los documentos
  34, 35 y 36.
- JSON Schema Draft 2020-12: esquema válido y fixture existente validado.

No se ejecutará build, despliegue ni publicación.

## Fuentes y artículos

A1, A2, A3 y A5 tienen nueva redacción en `review` basada únicamente en
localizaciones verificadas de S06-S07. A4 continúa bloqueado. S08-S10 no fueron
recuperadas mediante los repositorios e índices legítimos consultados.

## Riesgos pendientes

- Ningún borrador tiene todavía aprobación editorial y jurídica final.
- `originalWork` exige una declaración interna real y revisión documentada antes
  de usarse fuera de fixtures.
- La compatibilidad de una licencia o excepción sigue siendo una conclusión que
  debe aportar una revisión competente, no el software.
- No existe contenido cultural real incorporado al catálogo distribuido.
