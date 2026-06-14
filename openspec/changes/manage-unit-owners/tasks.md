## 1. Backend — autorización y rutas

- [x] 1.1 Crear `UnitOwnershipPolicy` con `create?`, `update?`, `destroy?` y scope por tenant
- [x] 1.2 Agregar rutas anidadas `ownerships` bajo `residential_properties/:id/units/:unit_id`
- [x] 1.3 Crear `Admin::ResidentialProperties::UnitOwnershipsController` (create, update, destroy)
- [x] 1.4 Registrar policy en `ApplicationPolicy` / convención Pundit si aplica

## 2. Backend — servicios y validaciones

- [x] 2.1 Implementar `UnitOwnerships::Create` (persona existente + datos de asignación)
- [x] 2.2 Implementar `UnitOwnerships::CreateWithPerson` (persona nueva + ownership en transacción)
- [x] 2.3 Implementar `UnitOwnerships::Update` (porcentaje, fechas, estado)
- [x] 2.4 Implementar `UnitOwnerships::Destroy` como baja lógica mediante `acts_as_paranoid`, sin hard delete
- [x] 2.5 Añadir validación unicidad persona+unidad con ownership activo
- [x] 2.6 Añadir traducciones de errores en `es` / `en` / `pt`
- [x] 2.7 Ejecutar create/update/destroy dentro de transacción y bloquear la unidad con `unit.with_lock` antes de recalcular porcentajes
- [x] 2.8 Prevenir duplicación de personas al crear desde drawer usando `document_number_digest` y email normalizado

## 3. Backend — serializers y respuestas

- [x] 3.1 Definir strong params para ownership y persona mínima en create
- [x] 3.2 Asegurar redirección Inertia a `units#show` con errores en drawer/form
- [x] 3.3 Verificar que `Unit::OwnershipStats` y `Unit::ChangeHistory` se actualizan tras mutaciones

## 4. Frontend — drawer agregar propietario

- [x] 4.1 Implementar paso `search`: búsqueda paginada de personas (reutilizar patrón People index)
- [x] 4.2 Implementar paso `create`: formulario persona mínima (reutilizar `Person/Form` o subconjunto)
- [x] 4.3 Implementar paso `assign`: porcentaje, fechas, preview de % disponible
- [x] 4.4 Conectar submit a `POST ownerships` vía Inertia con manejo de errores
- [x] 4.5 Actualizar stepper y navegación back/cancel entre pasos

## 5. Frontend — tabla y acciones de fila

- [x] 5.1 Habilitar menú de acciones por fila en `UnitOwnersTable`
- [x] 5.2 Implementar edición de ownership usando drawer/modal reutilizando el paso assign
- [x] 5.3 Implementar acción eliminar/desactivar con confirmación, ejecutando soft delete mediante `acts_as_paranoid`
- [x] 5.4 Refrescar listado y métricas tras cada operación (`preserveScroll`)

## 6. Tests

- [x] 6.1 Tests de servicios: cap 100%, fechas, duplicado activo, rollback transaccional
- [x] 6.2 Tests de controller/policy: autorización y respuestas Inertia
- [x] 6.3 Test de integración mínimo para flujo create con persona existente
- [x] 6.4 Test de concurrencia/lock para evitar superar 100% con operaciones simultáneas
- [x] 6.5 Test de soft delete: el ownership no aparece como activo, no cuenta en métricas y no se elimina físicamente

## 7. Verificación manual

- [ ] 7.1 Probar alta por búsqueda, alta por persona nueva, edición y finalización en UI
- [ ] 7.2 Verificar historial de cambios y métricas tras cada acción
- [ ] 7.3 Verificar paginación del listado con más de una página de propietarios
