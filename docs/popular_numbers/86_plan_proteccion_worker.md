# Plan de protección del Worker staging

Fecha: 2026-11-09.

## Estado de partida

- Worker previsto: `sorteosdominicanos-api-staging`.
- Worker remoto: todavía no existe.
- D1: `sorteosdominicanos-db-staging`.
- Binding: `HISTORY_DB`.
- Configuración: `loterias_rd_api/wrangler.staging.toml`.
- `workers_dev = false`.
- `preview_urls = false`.
- Rutas y Custom Domains: ninguno configurado.
- Aplicaciones Access: ninguna observada.
- Políticas Access: ninguna observada.

La configuración local mantiene el Worker sin entrada HTTP normal cuando sea
creado. Esto permite asociar Access antes de habilitar un hostname.

## Orden seguro de activación

1. Confirmar manualmente la dirección administrativa exacta y comprobar que
   autentica con el proveedor Cloudflare de la organización.
2. Verificar cuenta, team name, D1, UUID y configuración staging.
3. Crear o desplegar el Worker staging manteniendo `workers_dev=false`,
   `preview_urls=false`, sin rutas y sin Custom Domains.
4. Obtener y verificar el identificador real del Worker.
5. Crear una política reutilizable `Allow` para un correo exacto, sin
   `Everyone`, dominios amplios ni `Bypass`.
6. Asociar una aplicación Access al destino `worker` exacto y seleccionar
   `All traffic`.
7. Comprobar en el panel que la aplicación apunta solo al Worker staging y que
   la política contiene una única identidad autorizada.
8. Habilitar una sola entrada aprobada, preferiblemente después de completar
   las pruebas de configuración. No habilitar simultáneamente `workers.dev` y
   un Custom Domain.
9. Probar primero una solicitud anónima y una identidad no autorizada. Ambas
   deben ser bloqueadas antes de ejecutar el Worker.
10. Probar la identidad autorizada y después cada ruta funcional.
11. Confirmar que producción y los conteos de D1 no cambiaron.

Cada paso que cree, despliegue o modifique recursos requiere autorización
separada. Este documento no autoriza su ejecución.

## Superficies y rutas

### Worker completo

La aplicación Access a nivel de Worker debe cubrir producción y previews. Si en
el futuro se agrega una ruta, Custom Domain o hostname `workers.dev`, la misma
protección seguirá asociada al Worker.

### Previews

Permanecen desactivadas en Wrangler. No deben habilitarse antes de comprobar la
aplicación Access. Si se habilitan después, deben quedar incluidas en `All
traffic`.

### workers.dev

Permanece desactivado. Si se autoriza como entrada, se habilitará solo después
de verificar Access. La URL no debe utilizarse como excepción pública.

### Custom Domains

No existe uno autorizado. Crear un Custom Domain implicaría DNS y una fase
separada. No debe agregarse una aplicación por hostname que prevalezca sobre la
regla del Worker con una política más débil.

## Plan de pruebas

- anónimo: bloqueado por Access;
- identidad autorizada: acceso permitido;
- identidad autenticada distinta: bloqueada;
- `/health`: protegido y responde solo después de autenticación;
- `/statistics/*`: protegido y sin mezcla de series;
- `/internal/history/backfill`: Access primero y token interno después;
- ruta desconocida: Access primero y `404` solo para identidad autorizada;
- preview y hostname alternativo: inexistentes o protegidos;
- errores: sin cookies, JWT, tokens ni detalles internos;
- producción: Worker `api` y `sorteosdominicanos-app` sin cambios;
- D1: sin escrituras producidas por las pruebas de lectura.

## Criterios de detención

- cuenta, team name, Worker, D1 o UUID inesperados;
- identidad exacta no confirmada;
- política con `Everyone`, dominio de correo o `Bypass`;
- aplicación vinculada a todos los Workers o a producción;
- aparición de un hostname o preview público antes de Access;
- respuesta anónima directa del Worker;
- cualquier cambio no autorizado en producción o D1.
