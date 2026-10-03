## Why

The mobile app's first real (non-placeholder) menu section is the visit-invitation flow: a resident picks one of their units and invites a visitor. `Api::V1::Private::Units::VisitsController#create` already implements resident-initiated authorized-visit creation, but it lives under `api/v1/private`, which requires a resolved tenant (`ActsAsTenant.current_tenant` set from the request subdomain via `Api::V1::BaseController#set_current_organization`). The mobile client has no subdomain — its login (`mobile-client-auth`) deliberately authenticates without resolving any organization — so it cannot reach that endpoint, and it has no way to know which unit(s) it is even allowed to invite a visitor for.

This change adds the mobile-native equivalents, under `api/v1/mobile`, that resolve organization/tenant explicitly per request instead of from a subdomain — the same pattern established for mobile login and `/me`.

## What Changes

- Add `GET /api/v1/mobile/units`, returning the authenticated user's units — across all organizations they belong to — where they hold both `create_visits` and `authorize_visits` capability. Each entry includes enough organization and unit identity to disambiguate and to drive the subsequent create call.
- Add `POST /api/v1/mobile/units/:unit_id/visits`, creating an `authorized` visit for that unit, mirroring `Api::V1::Private::Units::VisitsController#create`'s contract and validation (visitor name/document/phone, `scheduled_at`), but resolving the unit's organization explicitly instead of trusting an already-set tenant.
- New `Api::V1::Mobile::UnitsController` and `Api::V1::Mobile::Units::VisitsController`, both under `Api::V1::Mobile::BaseController` (tenant-less, JWT-authenticated).

## Capabilities

### New Capabilities

- `mobile-visit-creation`: the resident-facing mobile flow for listing eligible units and creating an authorized visit against one of them.

### Modified Capabilities

_None._ `mobile-client-auth` is unchanged; this change only depends on it (authentication).

## Impact

- **Routes**: `config/routes.rb` — inside the existing `namespace :mobile`, add `resources :units, only: [:index] { resources :visits, only: [:create], module: :units }`.
- **Controllers**: new `app/controllers/api/v1/mobile/units_controller.rb`, new `app/controllers/api/v1/mobile/units/visits_controller.rb`.
- **Services**: reuses `Residents::VisitContext` and `Residents::CreateAuthorizedVisit` (both already organization-parameterized, not tenant-implicit) — no changes expected, pending confirmation while reading them in design.
- **Models**: none. Reads existing `User#people`, `Person`/`UnitOccupancy`/`UnitOwnership`, `Unit`, `Organization`.
- **Tenant isolation**: every query in the new controllers is either explicitly organization-scoped (unit lookup, capability resolution) or wrapped in `ActsAsTenant.with_tenant(organization)` for the write — never relies on an ambient `Current.organization`/subdomain-derived tenant, since mobile requests carry none.
- **Tests**: new `test/controllers/api/v1/mobile/units_controller_test.rb`, new `test/controllers/api/v1/mobile/units/visits_controller_test.rb`.

## Non-goals

- No visit listing/history endpoint for mobile (e.g. `GET /api/v1/mobile/visits`) — a separate change once the "view past visits" screen is scoped.
- No pending-visit flow (mobile creation is `authorized`-only, same restriction as the existing private endpoint).
- No push-notification wiring for visit status changes.
- No changes to the admin/Inertia visit management flow or its endpoints.
- No changes to `Residents::VisitContext` / `Residents::CreateAuthorizedVisit` beyond what's needed to keep them tenant-explicit instead of tenant-implicit (to be confirmed in design.md).
