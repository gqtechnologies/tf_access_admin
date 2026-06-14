## Context

El proyecto es una app Rails + Inertia + Vue multi-tenant para administración de propiedades residenciales. El dominio **Units / UnitOwnerships / Persons** ya existe en base de datos y en importación masiva (`BulkImportServices::ImportUnitOwnership`).

**Estado actual (implementado parcialmente):**
- Vista `admin/units/show` con header, métricas, pestaña Propietarios, tabla paginada y sidebar de historial (`Unit::ChangeHistory` vía `audited`).
- Drawer `UnitAddOwnerDrawer` con paso 1 (elegir buscar vs crear); pasos 2–4 son placeholders.
- `UnitsController#show` es solo lectura para ownerships.
- Validaciones en `UnitOwnership`: porcentaje activo ≤ 100%, `ends_at >= starts_at`, soft delete (`acts_as_paranoid`).

**Restricciones:** Pundit, `acts_as_tenant`, serializers admin, convenciones CRUD existentes (People, PropertySections), auditoría obligatoria para cambios de propiedad.

## Goals / Non-Goals

**Goals:**
- Permitir a un admin de tenant dar de alta un propietario en una unidad (persona existente o nueva).
- Permitir editar porcentaje, vigencia y estado de un ownership activo.
- Permitir finalizar/desactivar un ownership preservando historial.
- Mantener métricas, paginación y timeline sincronizados tras cada mutación.
- Reutilizar componentes modulares del drawer y tabla ya iniciados.

**Non-Goals:**
- Gestión de residentes, vehículos, visitas u otras pestañas de la unidad.
- Edición completa de la ficha de `Person` desde este flujo (solo creación mínima o vínculo).
- Importación masiva de propietarios (ya cubierta por bulk import).
- Portal self-service para propietarios.
- Cambios de esquema DB salvo índices/constraints menores si surgen en revisión.

## Decisions

### 1. Rutas anidadas bajo unidad

```
POST   /admin/residential_properties/:id/units/:unit_id/ownerships
PATCH  /admin/residential_properties/:id/units/:unit_id/ownerships/:id
DELETE /admin/residential_properties/:id/units/:unit_id/ownerships/:id 
```
**Nota:** `DELETE` representa baja lógica mediante `acts_as_paranoid`; no debe eliminar físicamente el ownership. La acción debe preservar historial y auditoría.

**Rationale:** Mantiene el contexto de unidad, alinea con `UnitsController` existente y simplifica autorización (`unit` como scope padre).

**Alternativa descartada:** `resources :unit_ownerships` top-level — peor UX de URLs y más riesgo de cross-tenant si el scope no es estricto.

### 2. Service objects para mutaciones

- `UnitOwnerships::Create` — crea ownership; opcionalmente crea `Person` si el flujo es “nueva persona”.
- `UnitOwnerships::Update` — actualiza campos permitidos.
- `UnitOwnerships::End` — finaliza el ownership seteando `ends_at`, `status: inactive` y actor de auditoría si aplica, sin eliminación física.

**Rationale:** Reglas de negocio (cap 100%, vigencia, auditoría) fuera del controller; reutilizable en tests y futuros jobs.

**Alternativa descartada:** Lógica en controller — viola convenciones del proyecto.

### 3. Drawer multi-paso (4 pasos)

| Paso | ID | Contenido |
|------|-----|-----------|
| 1 | `choose` | Buscar vs crear (ya implementado) |
| 2a | `search` | Búsqueda paginada de `Person` (ransack/display_name) |
| 2b | `create` | Form mínimo persona (reutilizar campos de `Person` CRUD) |
| 3 | `assign` | Porcentaje, `starts_at`, `ends_at` opcional; preview de % disponible |
| 4 | `confirm` | Revisión y confirmación antes de crear |

**Rationale:** Coincide con mockups; un solo drawer orquestado por `useUnitAddOwnerDrawer`.

### 4. Respuestas Inertia

Tras `create`/`update`/`destroy`, redirigir a `units#show` (pestaña owners) con `preserveScroll` o `router.reload` en Vue — patrón ya usado en People index.

**Alternativa:** JSON API parcial — no alineado con stack Inertia del admin.

### 5. Autorización

- `UnitOwnershipPolicy` con `create?`, `update?`, `destroy?` requiriendo `admin?` + `same_organization?` vía `unit` y `person`.
- Scope: ownerships de unidades en tenant actual.

### 6. Persona nueva en flujo de alta

Reutilizar validaciones de `Person` y `OrganizationMembership` si el proyecto exige membership al crear — delegar a servicio compartido o extraer de `PeopleController` lo mínimo.

**Decisión:** Crear persona con campos mínimos (`display_name`, documento, email) sin rol obligatorio salvo que el modelo lo exija.

### 7. Acciones de fila en tabla

Menú contextual por ownership: **Editar** (drawer o modal con assign step), **Finalizar vigencia**, **Desactivar**.

Finalizar vigencia:
- set ends_at
- status inactive
- mantiene histórico

Desactivar:
- acción administrativa inmediata
- ejecuta baja lógica mediante `acts_as_paranoid`
- conserva registro histórico y auditoría
- no elimina físicamente el ownership

Edición reutiliza formulario de asignación en modo `edit`.

## Risks / Trade-offs

| Riesgo | Mitigación |
|--------|------------|
| Condición de carrera al asignar % (dos admins simultáneos) | Ejecutar mutaciones dentro de transacción y bloquear la unidad con `unit.with_lock` antes de recalcular porcentaje activo; mensaje claro si supera 100% |
| Duplicar persona al crear desde drawer | Antes de crear, buscar coincidencias por `document_number_digest` y email normalizado dentro de la organización actual; si existe match, sugerir reutilizar persona existente |
| Drawer complejo con muchos estados | Composable `useUnitAddOwnerDrawer` + pasos aislados; tests de composable |
| Historial incompleto si job sin `current_user` | Servicios setean contexto audit; jobs futuros deben pasar actor |
| Re-render pesado de show tras cada acción | `preserveScroll` + paginación server-side ya existente |

## Migration Plan

1. Implementar backend (policy, rutas, servicios, controller) con tests.
2. Completar pasos 2–3 del drawer y acciones de tabla.
3. Habilitar botones hoy deshabilitados (agregar, editar, menú fila).
4. Verificar auditoría e historial en entorno de staging con unidad de prueba.
5. **Rollback:** deshabilitar rutas nuevas; UI vuelve a solo lectura (estado actual).

## Open Questions

- ¿Al finalizar ownership se exige `ends_at = hoy` o fecha libre en el pasado?
- ¿Una persona puede tener dos ownerships activos simultáneos en la misma unidad? (asumir **no** — validar unicidad persona+unidad+activo)
- ¿El botón eliminar debe finalizar vigencia antes de ejecutar soft delete, o solo aplicar baja lógica con `acts_as_paranoid`? Asumir soft delete auditado sin hard delete.

## UX Constraints

### Drawer Footer Layout

Todos los drawers del flujo de administración de propietarios deben utilizar un footer consistente.

Reglas:

- Los botones de navegación y acción deben estar ubicados en el footer del drawer.
- El footer debe utilizar `justify-between`.
- El botón secundario (Atrás, Cancelar) debe alinearse a la izquierda.
- El botón principal (Continuar, Guardar, Confirmar) debe alinearse a la derecha.
- No centrar botones horizontalmente.
- No utilizar layouts con botones apilados verticalmente salvo en pantallas móviles extremadamente pequeñas.
- Todos los pasos del flujo deben reutilizar el mismo componente de footer.

Ejemplo:

[Cancelar]                               [Continuar]

[Atrás]                                  [Guardar]

[Atrás]                                  [Confirmar]