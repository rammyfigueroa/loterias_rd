# Seguridad de una futura API pública

Fecha: 2026-11-09.

## Decisión principal

Cloudflare Access continúa protegiendo staging y no debe desactivarse. Sus
cookies administrativas o service tokens no deben incorporarse en Flutter:
cualquier secreto distribuido en una aplicación móvil puede extraerse y dejaría
de representar una identidad administrativa confiable.

La aplicación pública requiere una superficie distinta de solo lectura.

## Arquitectura propuesta

Opción preferida: un entrypoint público dedicado a estadísticas de lectura que:

1. exponga únicamente `GET /statistics/number-transitions` y `/health` mínimo;
2. valide método, ruta, serie, número, rango, cobertura, límite y cursor;
3. use un binding D1 histórico dedicado y revisado;
4. no exporte backfill, migraciones ni rutas administrativas;
5. comparta motor puro mediante código o service binding, no mediante la URL de
   staging;
6. devuelva solo campos públicos del contrato;
7. aplique rate limiting, caché, observabilidad y respuestas de error genéricas.

Alternativa condicionada: ampliar el Worker público `api` con una ruta de solo
lectura. Solo es aceptable tras inventariar su despliegue real, añadir un binding
D1 correcto y demostrar que las rutas administrativas permanecen ausentes o
aisladas. El checkout actual no permite confirmar esas condiciones.

## Controles

### Validación

- lista explícita de series autorizadas;
- consultas D1 preparadas y parametrizadas;
- límite y cursor acotados;
- rango dentro de cobertura;
- tamaño máximo de respuesta;
- solo GET, sin cuerpos de solicitud;
- CORS limitado a clientes web necesarios; CORS no autentica aplicaciones
  móviles ni sustituye controles de abuso.

### Rate limiting

Aplicar límite por ruta y actor disponible, con respuesta `429` y telemetría.
La API de Rate Limiting de Workers es aproximada y eventualmente consistente;
sirve para mitigación de abuso, no para contabilidad estricta. Un límite global
estricto requeriría otra arquitectura.

Fuente oficial: <https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/>.

### Caché

Las consultas son GET y dependen de una revisión de datos. La clave debe incluir
serie, número, rango, cobertura, paginación y fingerprint. Deben definirse
`Cache-Control`, TTL corto, invalidación por revisión y comportamiento ante
errores; no cachear respuestas administrativas o con autorización.

Fuente oficial: <https://developers.cloudflare.com/workers/cache/>.

### D1

El Worker debe usar el binding D1 y consultas preparadas. No se propone exponer
la API REST de D1 ni credenciales de cuenta. Las rutas públicas reciben datos
agregados, nunca payloads crudos del proveedor.

Fuente oficial: <https://developers.cloudflare.com/d1/best-practices/query-d1/>.

### Observabilidad

Registrar estado, latencia, ruta normalizada, resultado del rate limit y código
de error. No registrar cookies, tokens, correos, cursores completos, payloads
crudos ni datos personales. Separar métricas públicas de logs administrativos.

## Separación administrativa

- staging permanece bajo Access All traffic;
- backfill permanece privado y con autorización adicional;
- ninguna credencial Access se compila en Flutter;
- producción pública no obtiene acceso a rutas de escritura;
- despliegue público y despliegue administrativo usan configuraciones y
  bindings explícitos;
- una prueba negativa debe comprobar que rutas internas no existen públicamente.

## Riesgos

- scraping y consultas combinatorias sobre 100 números y rangos;
- caché obsoleta tras correcciones;
- enumeración de series o metadatos internos;
- respuestas grandes por paginación mal acotada;
- mezcla accidental de D1 staging y producción;
- despliegue sobre el Worker `api` sin inventario completo;
- interpretación predictiva por parte del usuario.

La UI y el API deben conservar el tamaño de muestra, cobertura y descargo no
predictivo.
