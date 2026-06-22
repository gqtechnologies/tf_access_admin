# Improve Property Foundation Tasks

> Las tareas describen implementación futura. Este change no implementa código y ninguna tarea está completada.

## 1. Modelo y migraciones

* [x] 1.1 Auditar datos existentes: nombres duplicados, nombres vacíos y estados no canónicos
* [x] 1.2 Definir constantes/enums para `active`, `inactive` y `archived`
* [x] 1.3 Añadir constraint de estado permitido
* [x] 1.4 Definir columna o expresión normalizada para unicidad case-insensitive del nombre
* [x] 1.5 Añadir índice único por organización para nombres normalizados no eliminados
* [x] 1.6 Verificar FK y `NOT NULL` de `organization_id`, `name`, `property_type` y `status`
* [x] 1.7 Revisar asociaciones `dependent: :destroy` para evitar cascadas durante lifecycle de propiedad
* [x] 1.8 Definir auditoría mínima de cambios de estado y lifecycle

## 2. Validaciones y normalización

* [ ] 2.1 Normalizar nombre mediante trim, colapso de whitespace y comparación case-insensitive
* [ ] 2.2 Validar nombre único dentro de la organización con error de campo
* [ ] 2.3 Mantener código opcional y único por organización cuando está presente
* [ ] 2.4 Validar inclusión de `property_type`
* [ ] 2.5 Validar inclusión de `status`
* [ ] 2.6 Definir validación de ubicación mínima y timezone
* [ ] 2.7 Impedir cambio de `organization_id`
* [ ] 2.8 Manejar `RecordNotUnique` concurrente como error de dominio

## 3. Servicios de dominio

* [ ] 3.1 Implementar `Properties::Create`
* [ ] 3.2 Implementar `Properties::Update`
* [ ] 3.3 Implementar `Properties::Archive`
* [ ] 3.4 Derivar organización desde contexto confiable en create
* [ ] 3.5 Centralizar normalización y validaciones de lifecycle
* [ ] 3.6 Separar activate/deactivate de cambios descriptivos cuando corresponda
* [ ] 3.7 Hacer archive no destructivo, atómico e idempotente
* [ ] 3.8 Preservar secciones, unidades, personas relacionadas, assignments, visitas y datos operativos al archivar
* [ ] 3.9 Definir errores/resultados estructurados para controller y UI

## 4. Policy y scopes

* [ ] 4.1 Alinear `ResidentialPropertyPolicy` con acciones index/show/create/update/archive
* [ ] 4.2 Mantener `manage_properties` como capability organizacional
* [ ] 4.3 Mantener `manage_property` acotada a propiedades con assignment activo
* [ ] 4.4 Permitir create/archive a tenant admin dentro de su organización
* [ ] 4.5 Permitir view/update a property admin solo en propiedades asignadas
* [ ] 4.6 Denegar create/archive a property admin por defecto
* [ ] 4.7 Denegar assignments inactivos, futuros o vencidos
* [ ] 4.8 Garantizar scopes tenant-safe y cross-property
* [ ] 4.9 No introducir roles globales de `property_admin`

## 5. Controllers y props

* [ ] 5.1 Delegar create a `Properties::Create`
* [ ] 5.2 Delegar update a `Properties::Update`
* [ ] 5.3 Reemplazar destroy ordinario por una acción explícita de archive
* [ ] 5.4 Delegar archive a `Properties::Archive`
* [ ] 5.5 Mantener carga de registros mediante policy scope
* [ ] 5.6 Unificar contrato de errores Inertia
* [ ] 5.7 Exponer permisos backend-driven para editar, activar/desactivar y archivar
* [ ] 5.8 Evitar aceptar `organization_id` desde parámetros del cliente

## 6. UI mínima

* [ ] 6.1 Alinear schema frontend con estados canónicos
* [ ] 6.2 Mantener `archived` fuera del selector ordinario de creación/edición
* [ ] 6.3 Añadir acción separada de archive con confirmación explícita
* [ ] 6.4 Mostrar errores de nombre duplicado en el campo correspondiente
* [ ] 6.5 Mostrar estado archivado y limitar acciones según props backend
* [ ] 6.6 Definir estados loading, success, error y forbidden
* [ ] 6.7 Mantener el formulario como superficie de datos y no como fuente de reglas de lifecycle

## 7. Tests

* [ ] 7.1 Testear creación válida
* [ ] 7.2 Testear rechazo sin organización
* [ ] 7.3 Testear rechazo sin nombre
* [ ] 7.4 Testear nombre duplicado normalizado dentro de la misma organización
* [ ] 7.5 Testear mismo nombre en organizaciones distintas
* [ ] 7.6 Testear valores válidos e inválidos de status
* [ ] 7.7 Testear defaults y normalización
* [ ] 7.8 Testear que propiedades con secciones o unidades no se eliminan físicamente
* [ ] 7.9 Testear dependencias indirectas de personas y staff assignments
* [ ] 7.10 Testear visitas activas/futuras como dependencia
* [ ] 7.11 Testear archivado controlado y preservación de dependencias
* [ ] 7.12 Testear tenant admin dentro y fuera de su organización
* [ ] 7.13 Testear property admin asignado y no asignado
* [ ] 7.14 Testear assignment inactivo, futuro y vencido
* [ ] 7.15 Testear usuario sin permisos
* [ ] 7.16 Testear aislamiento cross-organization y cross-property
* [ ] 7.17 Testear delegación de controllers a servicios
* [ ] 7.18 Testear conflicto concurrente de unicidad
* [ ] 7.19 Testear contrato mínimo de serializer/props y acciones backend-driven

## 8. Cierre

* [ ] 8.1 Ejecutar suite de modelos, servicios, policies, requests y frontend
* [ ] 8.2 Ejecutar RuboCop y chequeos TypeScript/Vue
* [ ] 8.3 Verificar manualmente create, update, deactivate, activate y archive
* [ ] 8.4 Verificar que archive no altera dependencias
* [ ] 8.5 Ejecutar `openspec validate improve-property-foundation --type change --strict`
* [ ] 8.6 Ejecutar Graphify después de la implementación futura, no durante este change documental
* [ ] 8.7 Preparar cierre y registrar decisiones de Open Questions resueltas
