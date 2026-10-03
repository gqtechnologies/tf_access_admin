# Tasks

## 1. Backend

- [x] 1.1 `Authorization::ActiveRelationships.active_occupancies_of_unit` / `active_ownerships_of_unit` (D2); cubierto por el test del controlador.
- [x] 1.2 `Residents::UnitResidents` (D3, D4); cubierto por el test del controlador.
- [x] 1.3 Ruta y `Api::V1::Private::Units::ResidentsController#index` (D1); verificar con el test del controlador.

## 2. Tests

- [x] 2.1 `test/controllers/api/v1/private/units/residents_controller_test.rb`: listado, orden, persona dueña y ocupante, relaciones terminadas, bandera de autorización, 403, 404, 401, sin datos de contacto; verde con `PARALLEL_WORKERS=1 bin/rails test`.

## 3. Validación

- [x] 3.1 `bundle exec rubocop` sobre los archivos tocados y `bundle exec brakeman` sin advertencias nuevas.
