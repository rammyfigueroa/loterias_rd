# Preparación de commit controlado

## Estado Git auditado

Fecha de revisión: 09/11/2026.

- Siete archivos `.idea` están preparados en el índice y son ajenos al módulo.
- `results_page.dart` está modificado sin preparar.
- El módulo, sus pruebas, fixtures, documentación e iOS están sin seguimiento.
- Existe un `.DS_Store` sin seguimiento.
- No se creó commit ni se modificó el índice durante esta fase.

## Archivos que deben incluirse

### Configuración e integración

- `loterias_rd_app/lib/app/app_features.dart`
- `loterias_rd_app/lib/features/results/presentation/results_page.dart`

### Código del módulo

- `loterias_rd_app/lib/features/dreams_numbers/application/catalog_text.dart`
- `loterias_rd_app/lib/features/dreams_numbers/application/dream_description_analyzer.dart`
- `loterias_rd_app/lib/features/dreams_numbers/application/dreams_catalog_search.dart`
- `loterias_rd_app/lib/features/dreams_numbers/application/publishable_catalog.dart`
- `loterias_rd_app/lib/features/dreams_numbers/data/dreams_catalog_loader.dart`
- `loterias_rd_app/lib/features/dreams_numbers/domain/catalog_validation.dart`
- `loterias_rd_app/lib/features/dreams_numbers/domain/dreams_catalog.dart`
- `loterias_rd_app/lib/features/dreams_numbers/presentation/dream_decoder_page.dart`
- `loterias_rd_app/lib/features/dreams_numbers/presentation/dream_dictionary_page.dart`
- `loterias_rd_app/lib/features/dreams_numbers/presentation/dream_table_page.dart`
- `loterias_rd_app/lib/features/dreams_numbers/presentation/dreams_content_state.dart`
- `loterias_rd_app/lib/features/dreams_numbers/presentation/dreams_navigation.dart`
- `loterias_rd_app/lib/features/dreams_numbers/presentation/dreams_numbers_home_page.dart`
- `loterias_rd_app/lib/features/dreams_numbers/presentation/dreams_placeholder_pages.dart`
- `loterias_rd_app/lib/features/dreams_numbers/presentation/widgets/dreams_entry_widgets.dart`
- `loterias_rd_app/lib/features/dreams_numbers/presentation/widgets/dreams_shared_widgets.dart`

### Pruebas y fixture sintético

- `loterias_rd_app/test/dreams_numbers_catalog_test.dart`
- `loterias_rd_app/test/dreams_numbers_presentation_test.dart`
- `loterias_rd_app/test/dreams_numbers_review_catalog_test.dart`
- `loterias_rd_app/test/fixtures/dreams_numbers_fixture.json`

### Documentación, esquema y catálogo de revisión

- `docs/dreams_numbers/01_inventario_fuentes.md`
- `docs/dreams_numbers/02_matriz_procedencia.md`
- `docs/dreams_numbers/03_comparacion_tablas.md`
- `docs/dreams_numbers/04_investigacion_seis_ramas.md`
- `docs/dreams_numbers/05_evaluacion_derechos.md`
- `docs/dreams_numbers/06_vacios_documentales.md`
- `docs/dreams_numbers/07_recomendaciones_editoriales.md`
- `docs/dreams_numbers/08_revision_documental.md`
- `docs/dreams_numbers/09_investigacion_historica.md`
- `docs/dreams_numbers/10_permisos_y_solicitudes.md`
- `docs/dreams_numbers/11_catalogo_piloto.md`
- `docs/dreams_numbers/12_numerologia_dominicana.md`
- `docs/dreams_numbers/13_casos_descifrador.md`
- `docs/dreams_numbers/14_evaluacion_editorial.md`
- `docs/dreams_numbers/15_arquitectura_datos.md`
- `docs/dreams_numbers/16_esquema_json.md`
- `docs/dreams_numbers/17_reglas_validacion.md`
- `docs/dreams_numbers/18_resultados_pruebas.md`
- `docs/dreams_numbers/19_integracion_visual.md`
- `docs/dreams_numbers/20_estados_interfaz.md`
- `docs/dreams_numbers/21_validacion_fase4.md`
- `docs/dreams_numbers/22_auditoria_editorial_fase5.md`
- `docs/dreams_numbers/23_plan_catalogo_publicable.md`
- `docs/dreams_numbers/24_seguridad_editorial_fase5_2.md`
- `docs/dreams_numbers/25_modelo_evidencia_derechos.md`
- `docs/dreams_numbers/26_catalogo_cultural_piloto.md`
- `docs/dreams_numbers/27_validacion_fase5_3.md`
- `docs/dreams_numbers/28_revision_articulos.md`
- `docs/dreams_numbers/29_matriz_derechos_contenido.md`
- `docs/dreams_numbers/30_evidencia_bibliografica.md`
- `docs/dreams_numbers/31_propuesta_rights_evidence.md`
- `docs/dreams_numbers/32_solicitudes_autorizacion.md`
- `docs/dreams_numbers/33_catalogo_minimo_propuesto.md`
- `docs/dreams_numbers/34_ampliacion_rights_evidence.md`
- `docs/dreams_numbers/35_revision_articulos_culturales.md`
- `docs/dreams_numbers/36_validacion_fase5_5.md`
- `docs/dreams_numbers/37_catalogo_revision.md`
- `docs/dreams_numbers/38_matriz_aprobacion.md`
- `docs/dreams_numbers/39_validacion_fase5_6.md`
- `docs/dreams_numbers/40_revision_final_articulos.md`
- `docs/dreams_numbers/41_registro_autoria.md`
- `docs/dreams_numbers/42_revision_cultural.md`
- `docs/dreams_numbers/43_revision_juridica.md`
- `docs/dreams_numbers/44_estrategia_tabla_dominicana.md`
- `docs/dreams_numbers/45_plan_seis_ramas.md`
- `docs/dreams_numbers/46_produccion_editorial.md`
- `docs/dreams_numbers/47_expresiones_dominicanas.md`
- `docs/dreams_numbers/48_diccionario_piloto.md`
- `docs/dreams_numbers/49_numerologia_documental.md`
- `docs/dreams_numbers/50_casos_linguisticos.md`
- `docs/dreams_numbers/51_investigacion_asociaciones.md`
- `docs/dreams_numbers/52_validacion_fase5_8.md`
- `docs/dreams_numbers/53_expediente_editorial.md`
- `docs/dreams_numbers/54_autoria_y_titularidad.md`
- `docs/dreams_numbers/55_revision_cultural_juridica.md`
- `docs/dreams_numbers/56_matriz_decision.md`
- `docs/dreams_numbers/57_validacion_fase5_9.md`
- `docs/dreams_numbers/58_metodologia_tabla_independiente.md`
- `docs/dreams_numbers/59_ficha_investigacion.md`
- `docs/dreams_numbers/60_cuestionario_testimonios.md`
- `docs/dreams_numbers/61_criterios_independencia.md`
- `docs/dreams_numbers/62_catalogo_investigacion.md`
- `docs/dreams_numbers/63_plan_piloto_20_asociaciones.md`
- `docs/dreams_numbers/64_validacion_fase6_0.md`
- `docs/dreams_numbers/65_consentimiento_informado.md`
- `docs/dreams_numbers/66_privacidad_investigacion.md`
- `docs/dreams_numbers/67_seguridad_retencion.md`
- `docs/dreams_numbers/68_responsabilidades.md`
- `docs/dreams_numbers/69_formulario_piloto.md`
- `docs/dreams_numbers/70_guia_entrevistador.md`
- `docs/dreams_numbers/71_validacion_fase6_1.md`
- `docs/dreams_numbers/72_cierre_conservador.md`
- `docs/dreams_numbers/73_feature_flag.md`
- `docs/dreams_numbers/74_validacion_cierre.md`
- `docs/dreams_numbers/75_plan_futura_actualizacion.md`
- `docs/dreams_numbers/76_preparacion_commit.md`
- `docs/dreams_numbers/dreams_catalog.schema.json`
- `docs/dreams_numbers/review_catalog/dominican_cultural_review_catalog.json`

Total previsto después de crear este documento:

- 2 archivos de configuración e integración.
- 16 archivos Dart del módulo.
- 4 archivos de pruebas y fixture.
- 78 archivos documentales, de esquema o revisión.
- 100 archivos en la propuesta.

## Archivos que deben excluirse

Archivos ya preparados pero ajenos al módulo:

- `.idea/.gitignore`
- `.idea/caches/deviceStreaming.xml`
- `.idea/loterias_rd.iml`
- `.idea/markdown.xml`
- `.idea/misc.xml`
- `.idea/modules.xml`
- `.idea/vcs.xml`

Archivos sin seguimiento ajenos o temporales:

- `.DS_Store`
- Todo `loterias_rd_app/ios/`

No se detectaron APK, AAB, IPA, archivos de build, keystores, credenciales ni
archivos temporales adicionales entre los archivos sin seguimiento.

## Cambio mixto

`results_page.dart` es mixto por procedencia temporal: ya tenía la integración
visual del módulo antes de la Fase 7.0 y después recibió la bandera de cierre.
Su diff completo contra `HEAD` contiene únicamente:

- Imports del módulo y de la bandera.
- Parámetro inyectable `dreamsNumbersEnabled`.
- CARD condicionada.
- Entrada del menú condicionada.
- Navegación protegida.

No se observaron líneas ajenas a Sueños y Números en el diff actual. Aun así,
debe revisarse y prepararse con `git add -p` para evitar incluir futuros cambios
no relacionados.

## Seguridad

- `dreamsNumbersEnabled` permanece en `false`.
- El catálogo de revisión no aparece en los assets de producción.
- Los fixtures sintéticos permanecen bajo `test/`.
- No se encontraron firmas de claves privadas, tokens comunes de alto riesgo,
  archivos de credenciales, correos ni teléfonos en el conjunto propuesto.
- El catálogo conserva cero entradas y cero asociaciones numéricas.
- La feature flag no sustituye `PublishableCatalogGate` ni los controles de
  derechos y publicación.

## Riesgos

- Los archivos `.idea` ya están en el índice; deben retirarse del área de
  preparación antes del commit.
- Todo el árbol iOS está sin seguimiento y no pertenece a este commit.
- Como casi todo el módulo está sin seguimiento, omitir una ruta produciría un
  commit incompleto.
- La documentación contiene investigación y estados de revisión; no debe
  interpretarse como contenido autorizado para producción.
- El fixture contiene datos sintéticos deliberados y sólo debe conservarse como
  material de prueba.

## Comandos recomendados

Ejecutar únicamente después de aprobación humana:

```bash
git restore --staged -- \
  .idea/.gitignore \
  .idea/caches/deviceStreaming.xml \
  .idea/loterias_rd.iml \
  .idea/markdown.xml \
  .idea/misc.xml \
  .idea/modules.xml \
  .idea/vcs.xml

git add -- docs/dreams_numbers
git add -- loterias_rd_app/lib/app/app_features.dart
git add -- loterias_rd_app/lib/features/dreams_numbers
git add -- loterias_rd_app/test/dreams_numbers_catalog_test.dart
git add -- loterias_rd_app/test/dreams_numbers_presentation_test.dart
git add -- loterias_rd_app/test/dreams_numbers_review_catalog_test.dart
git add -- loterias_rd_app/test/fixtures/dreams_numbers_fixture.json
git add -p -- loterias_rd_app/lib/features/results/presentation/results_page.dart

git status --short
git diff --cached --check
git diff --cached --stat
git diff --cached
git commit -m "feat: preserve dreams and numbers module behind disabled feature flag"
```

No usar `git add .`. Verificar antes del commit que `.idea`, `.DS_Store` e
`ios/` no aparezcan en `git diff --cached --name-only`.

## Validación conocida

- `flutter test`: 134/134 pruebas aprobadas en la Fase 7.0.
- `flutter analyze`: 53 avisos preexistentes y ningún aviso nuevo.
- `git diff --check`: aprobado.
- JSON de esquema y catálogo: sintaxis válida.
