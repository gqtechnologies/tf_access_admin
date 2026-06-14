## Why

Los administradores de propiedades residenciales necesitan gestionar propietarios de cada unidad (alta, edición, baja lógica y consulta) desde la vista de gestión de unidad, con trazabilidad y respeto al tope del 100% de propiedad. Hoy existe la vista de unidad con listado paginado e historial de cambios, pero el flujo de **Agregar propietario** solo muestra el paso inicial; no hay endpoints ni acciones para crear, actualizar ni finalizar `unit_ownerships` desde el admin.

## What Changes

- Completar el flujo del drawer **Agregar propietario** (buscar persona existente, crear persona nueva, asignar porcentaje y vigencia).
- Exponer API/admin para **crear**, **actualizar** y **finalizar/desactivar** `UnitOwnership` anidado bajo una unidad.
- Habilitar acciones por fila en la tabla de propietarios (editar, cambiar porcentaje, finalizar vigencia, desactivar).
- Validar reglas de negocio existentes: suma de porcentajes activos ≤ 100%, fechas coherentes, aislamiento por organización.
- Registrar auditoría (`audited`) y reflejar cambios en el historial lateral de la unidad.
- Autorización con Pundit para todas las operaciones sobre ownerships.
- Traducciones `es` / `en` / `pt` para el flujo completo.

## Capabilities

### New Capabilities

- `unit-owner-management`: Administración de propietarios de una unidad desde la vista de gestión (listado, métricas, drawer multi-paso, CRUD de ownerships, validaciones y auditoría).

### Modified Capabilities

- _(ninguna — no existen specs previas en `openspec/specs/`)_

## Impact

**Bounded context:** Units + Persons + Unit Ownerships (admin).

**Modelos afectados:** `Unit`, `UnitOwnership`, `Person` (solo vinculación/reutilización).

**Servicios / casos de uso nuevos o extendidos:**
- Crear ownership (persona existente o nueva)
- Actualizar porcentaje, fechas y estado
- Finalizar/desactivar ownership sin borrado físico

**Controllers / rutas:**
- `Admin::ResidentialProperties::UnitsController#show` (props adicionales si aplica)
- Nuevo `Admin::ResidentialProperties::UnitOwnershipsController` (o equivalente anidado) con `create`, `update`, `destroy`/end

**Frontend (Inertia + Vue):**
- `UnitOwnersPanel`, `UnitOwnersTable`, `UnitAddOwnerDrawer` y pasos hijos
- Posible formulario de edición inline o drawer secundario

**Policies:** `UnitOwnershipPolicy`, extensión de `UnitPolicy` si aplica.

**Tests:** servicios de validación de porcentaje, requests del controller, flujos críticos del drawer.

**Sin cambios de esquema previstos** — la tabla `unit_ownerships` ya soporta el dominio; solo lógica y UI.

## Business Rules

- Una persona puede ser propietaria de múltiples unidades.
- Una unidad puede tener múltiples propietarios.
- No puede existir más de un ownership activo para la misma persona y unidad.
- La suma de ownership_percentage de ownerships activos no puede superar 100%.
- Finalizar un ownership no elimina el registro.
- Todos los cambios deben quedar auditados.
- Solo usuarios de la misma organización pueden ser asociados a una unidad.