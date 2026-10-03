## Why

En la app, la opción "Residentes" del menú de una unidad está inerte: un residente no puede ver quién más figura como ocupante o propietario de su unidad ni quién puede autorizar visitas. El dato existe (ocupaciones y propiedades activas) pero solo se ve en el admin web.

## What Changes

- Nuevo endpoint de solo lectura `GET /api/v1/private/units/:unit_id/residents`.
- Devuelve una entrada por persona con relación activa con la unidad: nombre, foto, tipos de relación (`owner` y/o el tipo de ocupación), si puede autorizar visitas y si es el usuario que consulta.
- Solo responde a quien tiene una relación activa con esa unidad; no expone correo, teléfono ni documento.

## Capabilities

### New Capabilities

### Modified Capabilities
- `mobile-private-api`: agrega el listado de residentes de una unidad.

## Impact

- `config/routes.rb`, `app/controllers/api/v1/private/units/residents_controller.rb` (nuevo), `app/services/residents/unit_residents.rb` (nuevo).
- Tests: `test/controllers/api/v1/private/units/residents_controller_test.rb`.
- Sin migraciones.
