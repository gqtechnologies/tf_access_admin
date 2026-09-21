# Tasks

> Orden: 1 → 2 → 3 → 4 → 5. Tests solo de los archivos tocados, `PARALLEL_WORKERS=1`. Mirror: `Concierge::VisitsController` (web) para la lógica, `Api::V1::Private::Units::VisitsController` para la forma de la API.

## 1. Rol `concierge` (D1)

- [x] 1.1 `Api::RoleResolver`: rama conserje antes de `visitor`, con la definición de asignación activa que ya use `Authorization`.
- [x] 1.2 `test/services/api/role_resolver_concierge_test.rb`.

## 2. Propiedades (D2)

- [x] 2.1 Concern `Api::ConciergePropertyContext` (en `app/controllers/concerns/api/`) (`concierge_property_ids`, `load_property!`).
- [x] 2.2 `Concierge::PropertiesController#index`, ruta e i18n `api.concierge.property_forbidden`.
- [x] 2.3 Tests (en `concierge/visits_controller_test.rb`, junto al resto del namespace).

## 3. Listado (D3, D4)

- [x] 3.1 `Api::Private::ConciergeVisitSerializer`.
- [x] 3.2 `Concierge::VisitsController#index`: pestañas, búsqueda, orden, contadores, paginación.
- [x] 3.3 Tests de listado.

## 4. Ingreso y salida (D5)

- [x] 4.1 `check_in` y `check_out` con rescates; i18n `api.concierge.invalid_transition`, `api.concierge.not_authorized`.
- [x] 4.2 Tests.

## 5. Cierre

- [x] 5.1 `bundle exec rubocop` sobre lo tocado y `bundle exec brakeman`.
