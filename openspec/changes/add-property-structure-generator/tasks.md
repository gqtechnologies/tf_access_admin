## 1. StructureTemplate y TemplateResolver

- [ ] 1.1 Crear `PropertySetup::StructureTemplate` — value object con `levels` (máx 2, cada nivel con `section_type`, `count`, `prefix`, `suffix_type: :letter | :number`), `units_per_leaf`, `identifier_format`
- [ ] 1.2 Crear `PropertySetup::StructureTemplateResolver` — retorna template sugerido dado un `property_type`; cubrir todos los tipos de la tabla (building, tower, condominium, horizontal_community, residential_complex, sector, mixed_use, other)
- [ ] 1.3 Escribir tests de `StructureTemplateResolver` para cada `property_type`

## 2. Servicios de generación en memoria

- [ ] 2.1 Crear `PropertySetup::GenerateSections` — recibe `StructureTemplate` y retorna array de structs `{ name:, section_type:, parent_name: }` sin persistir; soporta 1 y 2 niveles
- [ ] 2.2 Crear `PropertySetup::GenerateUnits` — recibe leaf sections del template y retorna array de structs `{ identifier:, section_name: }` interpolando tokens por `section_type`
- [ ] 2.3 Implementar interpolación de tokens `{tower}`, `{floor}`, `{sector}`, `{block}`, `{number}` con padding configurable
- [ ] 2.4 Escribir tests unitarios para `GenerateSections` (template 1 nivel, template 2 niveles, sufijo letra, sufijo numérico)
- [ ] 2.5 Escribir tests unitarios para `GenerateUnits` (tokens por section_type, padding, 1 y 2 niveles)

## 3. Preview de secciones (Step 2)

- [ ] 3.1 Crear `PropertySetup::PreviewSections` — usa `GenerateSections`, consulta DB para detectar duplicados de secciones, retorna `{ sections:, summary: }`
- [ ] 3.2 Implementar detección de duplicados de secciones contra DB (query `WHERE name IN (...)` scoped por `residential_property_id` y `organization_id`)
- [ ] 3.3 Implementar detección de conflictos internos en el batch de secciones
- [ ] 3.4 Escribir tests de `PreviewSections`: sin duplicados, con duplicados, con conflictos

## 4. Commit de secciones (Step 2)

- [ ] 4.1 Crear `PropertySetup::CommitSections` — filtra ítems `:new`, persiste secciones con `insert_all` en transacción
- [ ] 4.2 Añadir re-validación de unicidad dentro de la transacción (race condition)
- [ ] 4.3 Registrar auditoría via `Audited::Audit.create!` con `action: 'bulk_create'`, `auditable_type: 'PropertySection'`, user y metadata del lote
- [ ] 4.4 Escribir tests de `CommitSections`: commit exitoso, fallo por unicidad concurrente, auditoría registrada en tabla `audits`

## 5. Preview de unidades (Step 3)

- [ ] 5.1 Crear `PropertySetup::PreviewUnits` — usa `GenerateUnits`, valida límite máximo de unidades por organización, consulta DB para detectar duplicados de unidades, retorna `{ units:, summary: }`
- [ ] 5.2 Implementar detección de duplicados de unidades contra DB (query `WHERE identifier IN (...)` scoped por `residential_property_id` y `organization_id`)
- [ ] 5.3 Implementar detección de conflictos internos en el batch de unidades
- [ ] 5.4 Escribir tests de `PreviewUnits`: sin duplicados, con duplicados, con conflictos

## 6. Commit de unidades (Step 3)

- [ ] 6.1 Crear `PropertySetup::CommitUnits` — filtra ítems `:new`, persiste unidades con `insert_all` en transacción
- [ ] 6.2 Añadir re-validación de unicidad dentro de la transacción (race condition)
- [ ] 6.3 Registrar auditoría via `Audited::Audit.create!` con `action: 'bulk_create'`, `auditable_type: 'Unit'`, user y metadata del lote
- [ ] 6.4 Escribir tests de `CommitUnits`: commit exitoso, fallo por unicidad concurrente, auditoría registrada en tabla `audits`

## 7. Controllers y rutas

- [ ] 7.1 Crear `Admin::Properties::SectionsGeneratorController` con acciones `preview` y `commit` (POST), usando `PreviewSections` / `CommitSections`
- [ ] 7.2 Crear `Admin::Properties::UnitsGeneratorController` con acciones `preview` y `commit` (POST), usando `PreviewUnits` / `CommitUnits`
- [ ] 7.3 Autorizar ambos controllers con Pundit (capability de administración de propiedad)
- [ ] 7.4 Añadir rutas de ambos controllers bajo `resources :properties` en `config/routes.rb`
- [ ] 7.5 Crear serializers para las respuestas de preview (secciones y unidades por separado); incluir template activo en la respuesta del controller de secciones para que Step 3 conozca los tokens disponibles
- [ ] 7.6 Escribir tests de ambos controllers: preview y commit autorizados y denegados

## 8. Frontend — componentes de generación masiva

- [ ] 8.1 Crear `SectionsGeneratorForm.vue` — reemplaza `v-if="selectedMode === 'quick'"` en `Step2Structure.vue`; carga template sugerido por `property_type`, permite ajustar count y prefix por nivel y eliminar el nivel superior para reducir a 1 nivel; preview/commit via API
- [ ] 8.2 Mostrar tokens disponibles dinámicamente según niveles del template (`{tower}`, `{floor}`, `{sector}`, `{block}`, `{number}`) con botones de inserción en el campo de formato
- [ ] 8.3 Crear `UnitsGeneratorForm.vue` — formulario Step 3: tipo de unidad, formato de identificador con tokens dinámicos; `units_per_leaf` siempre heredado del wizard state como contexto no editable
- [ ] 8.4 Definir schemas Zod en `app/javascript/lib/schemas/` para cada formulario y conectar con VeeValidate
- [ ] 8.5 Implementar panel de preview en `SectionsGeneratorForm`: árbol de secciones con estado (`:new`/`:duplicate`/`:conflict`) y summary
- [ ] 8.6 Implementar panel de preview en `UnitsGeneratorForm`: tabla de unidades con estado y summary
- [ ] 8.7 Añadir i18n para todos los textos en ambos componentes (`es`, `en`, `pt`)

## 9. Consolidar units_per_leaf en Step 2

- [ ] 9.1 Eliminar campo `quantity_per_floor` del formulario de Step 3 (`Step3Units.vue`)
- [ ] 9.2 Actualizar `validateStep3` y schema Zod de Step 3 para no validar `quantity_per_floor`
- [ ] 9.3 Pasar `units_per_leaf` desde el `StructureTemplate` en wizard state al backend de generación de unidades (Step 3)
- [ ] 9.4 Leer `wizardState.structure_template.units_per_leaf` en Step 3 y pasarlo a `UnitsGeneratorForm` como contexto no editable

## 10. Integración con el wizard

- [ ] 10.1 Integrar `SectionsGeneratorForm` en Step 2 del wizard como opción del modo quick; pasar `property_type` de la propiedad para cargar el template sugerido
- [ ] 10.2 Calcular modos disponibles en Step 3 a partir de `wizardState.structure_mode`: si es `quick` → automático + importación + manual; si es `manual` o `none` → solo importación + manual
- [ ] 10.3 Integrar `UnitsGeneratorForm` en Step 3 solo cuando el modo automático está disponible (`structure_mode === 'quick'`)
- [ ] 10.4 Verificar flujo: Step 2 quick (building) → Step 3 automático → finish
- [ ] 10.5 Verificar flujo: Step 2 quick (condominium) → Step 3 automático → finish
- [ ] 10.6 Verificar flujo: Step 2 manual → Step 3 sin modo automático → importación o manual → finish
