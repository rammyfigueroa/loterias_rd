# Plan de aislamiento de staging

Fecha: 2026-11-09.

## Alternativas evaluadas

### A. Utilizar staging existente

No es viable actualmente: el Worker y la base D1 declarados para staging no
existen.

- Seguridad: no evaluable.
- Complejidad: baja si existiera, pero requiere creación real.
- Costos: ninguno puede atribuirse a un recurso inexistente.
- Riesgo: confundir la configuración local con infraestructura creada.
- Mantenimiento: no aplica.

### B. Crear staging en la cuenta correcta

Usar la cuenta que ya contiene `api` y `sorteosdominicanos-app`, con Worker y D1
exclusivos.

- Seguridad: adecuada si los IDs se verifican, no hay rutas/triggers y se
  controla el acceso a `workers.dev`.
- Complejidad: la menor; reutiliza la sesión, subdominio y operación existentes.
- Costos: comparte el plan y consumo de la cuenta; el costo exacto depende del
  plan y uso y debe revisarse antes de crear recursos.
- Riesgo: mayor radio de impacto operativo por compartir cuenta y credenciales
  con producción. Un comando/configuración incorrectos podría apuntar a `api`.
- Mantenimiento: sencillo, pero exige manifiesto de IDs y comandos siempre con
  `--config wrangler.staging.toml`.

### C. Crear staging en una cuenta separada

Usar otra cuenta Cloudflare dedicada.

- Seguridad: mayor separación administrativa y de consumo.
- Complejidad: alta; requiere otra cuenta, perfil, controles de acceso,
  facturación y operación separada.
- Costos: puede implicar plan o consumo independiente; no se estiman cifras sin
  conocer la modalidad elegida.
- Riesgo: menor impacto accidental sobre producción, pero mayor riesgo de
  configuración divergente y mantenimiento olvidado.
- Mantenimiento: más alto por perfiles, permisos y recursos duplicados.

## Recomendación

Recomendada: alternativa B, siempre que una fase autorizada aplique controles
estrictos. La cuenta de producción ya fue identificada y el Worker activo no usa
D1, por lo que un D1 nuevo con ID exclusivo puede aislar los datos históricos.

La alternativa C debe preferirse si el equipo requiere separación de permisos
o cumplimiento que impida compartir cuenta. No existe evidencia actual de esa
necesidad y supondría más operación.

## Recursos que sería necesario crear

Solo bajo autorización posterior:

1. Worker `sorteosdominicanos-history-staging`.
2. D1 `sorteosdominicanos-history-staging-db`.
3. Binding `HISTORY_DB` del Worker exclusivamente al nuevo ID D1.
4. Mecanismo de acceso aprobado para evitar exposición pública no controlada.
5. Dataset sintético reproducible, sin copia ni backfill de producción.

No se requiere custom domain para las pruebas técnicas si se aprueba una URL
`workers.dev` protegida o temporal. No debe crearse ruta, dominio o cron por
defecto.

## Controles obligatorios

- Registrar cuenta, nombres e IDs en un manifiesto antes de migrar.
- Comprobar que el nombre de script no sea `api` ni
  `sorteosdominicanos-app`.
- Comprobar que el ID D1 sea no cero y no aparezca en producción.
- Usar siempre `--config wrangler.staging.toml`.
- Ejecutar una pausa de revisión después de crear recursos y antes de aplicar
  migraciones.
- No configurar backfill ni `scheduled`.
- No copiar secretos de producción.
- Cargar solo fixtures sintéticos.
- Mantener pruebas y observabilidad sin payloads sensibles.
- Definir rollback que preserve evidencia y no toque recursos productivos.

## Secuencia futura propuesta, no ejecutada

1. Autorizar por separado la creación de los dos recursos.
2. Crear D1 y detenerse para revisar su ID.
3. Actualizar la configuración únicamente bajo autorización específica.
4. Aplicar migraciones al ID revisado.
5. Crear/desplegar el Worker de staging.
6. Verificar bindings, dominio y ausencia de rutas/triggers.
7. Cargar fixtures sintéticos.
8. Ejecutar el plan de pruebas del documento 35.
9. Eliminar o conservar staging solo según decisión humana posterior.

Esta secuencia no autoriza comandos remotos.
