# Tasks

> Orden: 1 → 2 → 3 → 4 → 5. Tests solo de los archivos tocados, `PARALLEL_WORKERS=1`. Mirror: `Concierge::VisitsController` (web) para la lógica, `Api::V1::Private::Units::VisitsController` para la forma de la API.

## 1. Rol `concierge` (D1)

- [ ] 1.1 `Api::RoleResolver`: rama conserje antes de `visitor`, con la definición de asignación activa que ya use `Authorization`.
- [ ] 1.2 `test/services/api/role_resolver_test.rb`.

## 2. Propiedades (D2)

- [ ] 2.1 Concern `PropertyContext` (`concierge_property_ids`, `load_property!`).
- [ ] 2.2 `Concierge::PropertiesController#index`, ruta e i18n `api.concierge.property_forbidden`.
- [ ] 2.3 Tests.

## 3. Listado (D3, D4)

- [ ] 3.1 `Api::Private::ConciergeVisitSerializer`.
- [ ] 3.2 `Concierge::VisitsController#index`: pestañas, búsqueda, orden, contadores, paginación.
- [ ] 3.3 Tests de listado.

## 4. Ingreso y salida (D5)

- [ ] 4.1 `check_in` y `check_out` con rescates; i18n `api.concierge.invalid_transition`, `api.concierge.not_authorized`.
- [ ] 4.2 Tests.

## 5. Cierre

- [ ] 5.1 `bundle exec rubocop` sobre lo tocado y `bundle exec brakeman`.
