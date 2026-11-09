# Seguridad, retención y retiro

## Clasificación de información

- **R1 — Respuesta bruta:** texto o audio autorizado antes de edición.
- **R2 — Consentimiento:** opciones aceptadas, fecha, versión y prueba.
- **R3 — Contacto opcional:** vía separada para seguimiento o retiro.
- **R4 — Evidencia editorial anonimizada:** asociación, contexto minimizado,
  procedencia y revisiones sin identidad.

## Seguridad propuesta

1. Almacenamiento privado administrado, con cifrado en tránsito y en reposo
   cuando el sistema aprobado lo permita.
2. Acceso por cuenta individual, mínimo privilegio y segundo factor.
3. R2 y R3 separados de R1/R4; nunca en repositorios Git públicos.
4. Registro de accesos, exportaciones, cambios y eliminaciones.
5. Copias de seguridad cifradas, con acceso y vencimiento equivalentes al
   original.
6. Exportaciones con campos permitidos y revisión previa; prohibida la inclusión
   de contactos o consentimientos en el catálogo.
7. Flutter, Worker y D1 no recopilarán ni almacenarán respuestas en esta fase.

La plataforma, ubicación y responsable de administración están pendientes.

## Plazos propuestos

Todos los plazos requieren aprobación jurídica y del responsable:

| Clase | Plazo propuesto | Acción al vencer |
|---|---|---|
| R1 respuestas brutas | 12 meses después de la última entrevista del piloto | Eliminar o convertir a R4 si existe autorización |
| R2 consentimientos | 5 años después del último uso autorizado | Revisar obligación y eliminar de forma segura |
| R3 contacto opcional | Hasta 90 días después del cierre del piloto o al retirarse | Eliminar antes si deja de ser necesario |
| R4 evidencia anonimizada | 5 años, con revisión anual | Renovar justificación o eliminar |
| Registros de seguridad | 12 meses, salvo incidente o requisito aprobado | Eliminar de forma controlada |

Una publicación aprobada tendría reglas distintas. No se promete retirar copias
ya distribuidas cuando ello sea técnicamente imposible; ese límite debe
explicarse antes de autorizar publicación.

## Procedimiento de retiro

1. Recibir solicitud por el canal pendiente y verificar el código de retiro.
2. Registrar fecha, alcance y responsable sin añadir identidad innecesaria.
3. Bloquear inmediatamente nuevos usos del registro.
4. Localizar R1-R4 y copias de seguridad mediante IDs, no por nombre.
5. Determinar qué puede eliminarse y qué obligación revisada exige conservarse.
6. Eliminar o anonimizar según la solicitud y registrar la operación.
7. Propagar la acción a copias de trabajo y marcar backups para expiración.
8. Confirmar resultado y límites dentro del plazo que se apruebe.

Si la solicitud se recibe antes de publicar, el registro no debe publicarse
mientras se procesa.

## Incidentes

Quien detecte pérdida, acceso indebido o exportación incorrecta debe detener el
acceso cuando sea seguro, preservar evidencias técnicas mínimas y avisar al
responsable de seguridad. Este debe evaluar alcance, datos afectados,
contención, recuperación y notificaciones requeridas con revisión jurídica. No
se fijan plazos regulatorios sin determinar jurisdicción.

## Eliminación

La eliminación debe cubrir originales, copias de trabajo y colas de exportación.
En backups inmutables se documentará la fecha de expiración y se impedirá la
restauración para uso ordinario. El método concreto depende de la plataforma
pendiente de selección.
