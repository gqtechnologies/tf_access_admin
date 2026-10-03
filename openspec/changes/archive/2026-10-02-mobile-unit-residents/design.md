## Context

`Authorization::ActiveRelationships` es la fuente única de qué ocupación/propiedad está vigente (estado y fechas) pero consulta por persona. `Unit.with_active_relationship_for(person, organization)` ya decide qué unidades ve un residente en `GET /units`. La foto vive en `User#avatar` (una persona sin cuenta no tiene foto).

## Goals / Non-Goals

**Goals:** listado de solo lectura con el mínimo dato personal necesario.

**Non-Goals:** agregar, editar o quitar residentes desde la app; contratos de arriendo; residentes autorizados (`authorized_residents`).

## Decisions

### D1 — Acceso = misma regla que `GET /units`
Si la unidad aparece en `Unit.with_active_relationship_for` para la persona, puede ver sus residentes; si no, `403`. No se usa `Residents::VisitContext` porque exige permisos de visitas que un propietario sin ocupación no tiene.

### D2 — Vigencia por unidad en `Authorization::ActiveRelationships`
Se agregan `active_occupancies_of_unit(unit)` y `active_ownerships_of_unit(unit)` con los mismos filtros de estado y fechas que los métodos por persona, para no duplicar la regla fuera del módulo.

### D3 — Una entrada por persona, armada en `Residents::UnitResidents`
El servicio agrupa ocupaciones y propiedades por `person_id` y devuelve hashes listos para JSON. `relationships` usa `"owner"` para la propiedad y `occupancy_type` tal cual para la ocupación (la app traduce). No hay serializer de ActiveModel porque el recurso no es un modelo.

### D4 — `can_authorize_visits` refleja solo la ocupación
Es el indicador que el residente entiende ("puede autorizar visitas"). Los permisos derivados de roles operativos no se muestran.

## Risks / Trade-offs

- [Exponer nombres de co-residentes] → Solo a quien ya tiene relación vigente con la unidad, y sin datos de contacto.
