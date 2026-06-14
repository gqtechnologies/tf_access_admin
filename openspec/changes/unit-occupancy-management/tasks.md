## 1. Backend — modelo y migraciones

- [ ] 1.1 Ampliar `OccupancyTypes` con: `owner_resident`, `tenant`, `family_member`, `temporary_resident`, `authorized_manager`, `other`
- [ ] 1.2 Migración de datos legacy (`owner` → `owner_resident`, `family` → `family_member`)
- [ ] 1.3 Añadir `deleted_at` a `unit_occupancies` y habilitar `acts_as_paranoid` en `UnitOccupancy`
- [ ] 1.4 Añadir índice único parcial por `(organization_id, unit_id, person_id)` considerando únicamente registros no eliminados (`deleted_at IS NULL`)
- [ ] 1.5 Validaciones modelo: unicidad activa persona+unidad, `ends_at >= starts_at`, inclusión de `occupancy_type` y `status`
- [ ] 1.6 Añadir `audited` a `UnitOccupancy` (campos clave, `associated_with: :unit`)
- [ ] 1.7 Scope/query `active_authorizers_for(unit)` para regla de visitas (sin integrar en `Visit` aún)

## 2. Backend — autorización y rutas

- [ ] 2.1 Crear `UnitOccupancyPolicy` con `create?`, `update?`, `destroy?` y scope por tenant
- [ ] 2.2 Agregar rutas anidadas `occupancies` bajo `residential_properties/:id/units/:unit_id`
- [ ] 2.3 Crear `Admin::ResidentialProperties::UnitOccupanciesController` (create, update, destroy)
- [ ] 2.4 Registrar policy en convención Pundit existente

## 3. Backend — servicios y validaciones

- [ ] 3.1 Implementar `UnitOccupancies::Create` (persona existente + datos de ocupación)
- [ ] 3.2 Implementar `UnitOccupancies::CreateWithPerson` (persona nueva + ocupación en transacción)
- [ ] 3.3 Implementar `UnitOccupancies::Update` (tipo, `can_authorize_visits`, fechas, status)
- [ ] 3.4 Normalizar `starts_at` al inicio del día y `ends_at` al final del día durante create/update
- [ ] 3.5 Implementar `UnitOccupancies::Destroy` como soft delete vía `acts_as_paranoid`
- [ ] 3.6 Reutilizar o extraer deduplicación de personas (`document_number_digest`, email normalizado) del flujo de propietarios
- [ ] 3.7 Añadir traducciones de errores y labels de `occupancy_type` en `es` / `en` / `pt`
- [ ] 3.8 Exponer ocupaciones activas de la persona seleccionada (propiedad, sección, unidad, tipo y fechas) para mostrar warning contextual durante la asignación

## 4. Backend — serializers y respuestas Inertia

- [ ] 4.1 Crear `Admin::UnitOccupancySerializer` incluyendo labels traducidos para `occupancy_type`
- [ ] 4.2 Extender `UnitsController#show` con props `occupancies` y paginación (pestaña occupants)
- [ ] 4.3 Strong params para ocupación y persona mínima en create
- [ ] 4.4 Redirección Inertia a `units#show` con errores en drawer/form (patrón ownerships)
- [ ] 4.5 Extender `Unit::ChangeHistory` para eventos de `UnitOccupancy`

## 5. Frontend — pestaña y tabla de ocupantes

- [ ] 5.1 Habilitar pestaña **Residentes / Ocupantes** en `admin/units/show.vue` (separada de Propietarios)
- [ ] 5.2 Crear `UnitOccupantsPanel` con tabla: nombre, documento, tipo, puede autorizar visitas, inicio, fin, estado, acciones
- [ ] 5.3 Paginación server-side y orden (activos primero, luego por `starts_at` desc)
- [ ] 5.4 Menú de acciones por fila: editar, activar/inactivar, eliminar (soft delete con confirmación)
- [ ] 5.5 Mostrar únicamente ocupantes activos por defecto y habilitar filtro/toggle para historial

## 6. Frontend — drawer agregar ocupante

- [ ] 6.1 Composable `useUnitAddOccupantDrawer` (pasos, estado, snapshot sessionStorage)
- [ ] 6.2 Paso `choose`: buscar persona existente vs crear nueva
- [ ] 6.3 Paso `search`: búsqueda paginada de personas (reutilizar patrón add-owner)
- [ ] 6.4 Paso `create`: formulario persona mínima (nombre, documento, email)
- [ ] 6.5 Paso `assign`: tipo de ocupación, `can_authorize_visits`, fechas
- [ ] 6.6 Paso `confirm`: resumen antes de submit
- [ ] 6.7 Footer drawer con `flex justify-between` (secundario izquierda, primario derecha)
- [ ] 6.8 Conectar submit a `POST occupancies` vía Inertia con manejo de errores
- [ ] 6.9 Mostrar warning destacado si la persona seleccionada posee una ocupación activa en otra unidad, indicando propiedad, sección y unidad actual
- [ ] 6.10 Paso `success`: pantalla de éxito mostrando ocupante asignado, unidad y acciones disponibles (cerrar drawer / ver ocupantes)

## 7. Frontend — drawer editar ocupación

- [ ] 7.1 Drawer/modal de edición reutilizando campos del paso `assign`
- [ ] 7.2 Conectar a `PATCH occupancies/:id` con `preserveScroll`
- [ ] 7.3 Acciones activar/inactivar y eliminar desde fila o drawer según patrón owners

## 8. Tests

- [ ] 8.1 Tests de servicios: unicidad activa, fechas, duplicado persona, rollback transaccional, soft delete
- [ ] 8.2 Tests de modelo: validaciones, scopes de authorizers, migración de tipos
- [ ] 8.3 Tests de controller/policy: autorización y respuestas Inertia
- [ ] 8.4 Tests de routing para rutas anidadas `occupancies`
- [ ] 8.5 Test de integración mínimo: create con persona existente y con persona nueva
- [ ] 8.6 Validar vigencia de autorizadores considerando status, deleted_at, starts_at y ends_at
- [ ] 8.7 Test de warning cuando la persona seleccionada posee ocupación activa en otra unidad

## 9. Verificación manual

- [ ] 9.1 Probar alta por búsqueda, alta por persona nueva, edición, activar/inactivar y soft delete en UI
- [ ] 9.2 Verificar separación visual Propietarios vs Residentes / Ocupantes
- [ ] 9.3 Verificar historial de cambios tras mutaciones de ocupación
- [ ] 9.4 Verificar paginación del listado con más de una página de ocupantes
- [ ] 9.5 Verificar que todos los drawers utilicen footer `flex justify-between` con acción secundaria a la izquierda y primaria a la derecha
