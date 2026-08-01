## 1. Routes

- [x] 1.1 In `config/routes.rb`, inside the existing `namespace :mobile`, add:
  ```ruby
  resources :units, only: [ :index ] do
    resources :visits, only: [ :create ], module: :units
  end
  ```

## 2. Mobile units listing

- [x] 2.1 Create `app/services/residents/eligible_units.rb` (or similar): given a `user`, returns `[{ organization:, unit: }]` pairs across all organizations, filtered to units where the person's active `UnitOccupancy`/`UnitOwnership` grants both `create_visits` and `authorize_visits`, evaluated via `Authorization::Resolver` per `(organization, unit)` pair inside `ActsAsTenant.with_tenant(organization)`. Derive the initial `(person, unit)` candidates via `ActsAsTenant.without_tenant { user.people... }` — see design.md decision 1.
- [x] 2.2 Create `app/controllers/api/v1/mobile/units_controller.rb`: `Api::V1::Mobile::UnitsController < Api::V1::Mobile::BaseController`, action `index`, calls the service from 2.1, renders `{ data: [ { id, name, organization: { id, name } }, ... ] }`.
- [x] 2.3 Create a serializer (or inline hash) for the units-list entry shape, mirroring an existing lightweight serializer's style rather than inventing a new pattern.

## 3. Mobile visit creation

- [x] 3.1 Create `app/controllers/api/v1/mobile/units/visits_controller.rb`: `Api::V1::Mobile::Units::VisitsController < Api::V1::Mobile::BaseController`.
  - `load_unit`: `@unit = ActsAsTenant.without_tenant { Unit.find(params[:unit_id]) }` (404 via existing `rescue_from ActiveRecord::RecordNotFound` on `not_found`).
  - Wrap the rest of the action in `ActsAsTenant.with_tenant(@unit.organization) do ... end`.
  - `authorize_resident!`: build `Residents::VisitContext.new(user: current_user, organization: @unit.organization, unit: @unit)`; render `403` with `I18n.t("api.visits.#{ctx.denial_reason}")` if not authorized — reuse the same i18n keys the private endpoint uses.
  - `create`: call `Residents::CreateAuthorizedVisit.call(unit:, visitor_params:, scheduled_at:, actor: current_user)`; render `{ data: { id, status } }`, `201`; rescue `ActiveRecord::RecordInvalid` → `422` with `record.errors.full_messages.to_sentence`, mirroring `Api::V1::Private::Units::VisitsController`.
- [x] 3.2 Confirm (do not change unless broken) that `Residents::VisitContext` and `Residents::CreateAuthorizedVisit` behave correctly when invoked from inside an explicit `ActsAsTenant.with_tenant` block rather than from `ApplicationController`'s filter-set tenant — they should, since neither references `Current.organization` directly, but verify via the new controller tests in section 5.

## 4. Authorization denial reasons

- [x] 4.1 Verify `I18n.t("api.visits.no_active_relationship")` and `I18n.t("api.visits.authorization_denied")` (or equivalent keys used by `Residents::VisitContext#denial_reason`) already exist in `es`/`en`/`pt` locale files (reused from the private endpoint); add only if missing for any locale.

## 5. Tests

- [x] 5.1 Create `test/controllers/api/v1/mobile/units_controller_test.rb`: eligible unit returned; unit without `can_authorize_visits` excluded; units across two organizations both returned; empty list when no eligible units; `401` when unauthenticated.
- [x] 5.2 Create `test/controllers/api/v1/mobile/units/visits_controller_test.rb`: successful creation (asserts `authorized` status, correct organization/unit persisted); `403` for a user with no `Person` in the unit's organization; `403` for a user with a `Person` in the organization but no relationship to this unit; `422` for invalid visitor/schedule payload; `401` when unauthenticated. Include at least one test that runs with **no** request subdomain set, to prove tenant resolution does not depend on it.
- [x] 5.3 Add a regression test (or extend an existing tenant-isolation test) proving `GET /api/v1/mobile/units` for user A never includes a unit that only user B has a relationship to, even when both belong to the same organization.

## 6. Validation

- [ ] 6.1 Run `bin/rails test test/controllers/api/v1/mobile/units_controller_test.rb test/controllers/api/v1/mobile/units/visits_controller_test.rb`. (Blocked locally — Docker daemon not running in this environment; run before merging.)
- [ ] 6.2 Run `graphify update app`. (Blocked locally — same reason.)
