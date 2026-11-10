# Arquitectura propuesta

## Estado existente verificado

- `dreams_catalog.dart` ya modela fuente, derechos, verificación y publicación.
- `PublishableCatalogGate` devuelve catálogo solo si la validación de
  publicación no produce incidencias.
- `AppFeatures.dreamsNumbersEnabled` permanece en `false`.
- El historial D1 identifica operador y sorteo, conserva cobertura y revisiones.
- El cliente estadístico pagina y envía `operatorId`, `drawId`, `from` y `to`.

## Componentes futuros

### Dominio cultural local

Ampliar el esquema solo después de aprobación para representar una
`PopularNumberRelation` con fuente, sujeto, objeto, tipo, dirección,
reciprocidad, localidad, período, variante, evidencia, derechos y estados. No
reutilizar `DocumentaryClaim` sin comprobar que expresa relaciones muchos-a-
muchos y dirección.

### Dominio estadístico remoto

Servicio D1 que calcule transiciones desde resultados históricos por serie. La
respuesta debería incluir filtros efectivos, cobertura, observaciones,
frecuencias, incertidumbre, paginación y descargo. Caché por combinación de
serie, posición, rango y versión de datos.

### Aplicación

Repositorio y controlador independientes para estadísticas y cultura. Invalidar
respuestas tardías al cambiar filtros, siguiendo el patrón actual de
`FirstPrizeStatisticsController`. No cargar catálogos bloqueados.

## Almacenamiento

- Asociaciones culturales aprobadas: asset versionado y validado; no requieren
  backend si son pequeñas y estáticas.
- Evidencia y material de revisión: fuera de assets de producción.
- Estadísticas históricas: D1, porque dependen de resultados y cobertura.
- Preferencias y caché efímera: local, sin datos sensibles.

## Rendimiento y pruebas

- Índice D1 por `draw_id`, posición, fecha y número de origen.
- Límites de rango, paginación y caché invalidable.
- Pruebas de aislamiento de series, huecos de cobertura, orden, empate,
  transición final, rango y respuestas tardías.
- Pruebas del gate para impedir contenido sin derechos o sin aprobación.

## Compatibilidad

La lógica común permanece en Dart puro y HTTP; Android/iOS no necesitan cambios
nativos. No se propone modificar dependencias en esta fase.
