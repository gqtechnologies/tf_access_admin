## Context

`Api::V1::Private::Units::VisitsController#create` (resident visit creation) and its collaborators — `Residents::VisitContext`, `Residents::CreateAuthorizedVisit`, `Residents::ResolveVisitorPerson`, `Visits::Create` — already implement everything this change needs *except* tenant resolution. They run under `Api::V1::Private::BaseController < Api::V1::BaseController`, which sets `Current.organization` / `ActsAsTenant.current_tenant` from the request subdomain before the action runs (`ApplicationController#set_current_organization`). Every model involved (`Unit`, `Person`, `Visit`, `UnitOccupancy`, …) declares `acts_as_tenant :organization`, and none of the service objects reference `ActsAsTenant.current_tenant` directly — they rely entirely on that ambient scope.

`acts_as_tenant` is **not** configured with `require_tenant = true` in this app (no such initializer). That means with no tenant set, its default scope does not raise — it silently returns unscoped (cross-organization) results. Concretely: `Unit.find(params[:unit_id])`, run with no tenant set, would find a unit belonging to *any* organization, not just ones the requesting user has any relationship to. The existing private controller is safe only because `ApplicationController` always sets a tenant first. Mobile requests never have a subdomain, so this ambient safety net does not exist here — the new mobile controllers must establish tenant scope themselves, explicitly, before touching any `acts_as_tenant` model.

## Goals / Non-Goals

**Goals:**
- Let a mobile `client_global?` user discover which unit(s), in which organization(s), they can invite a visitor for.
- Let that user create an `authorized` visit for one of those units, with the same validation and status rules as the existing private endpoint.
- Never run an `acts_as_tenant`-scoped query without an explicitly, correctly set tenant — given `require_tenant` is off, an unscoped query is a cross-tenant data leak, not a loud failure.
- Reuse `Residents::VisitContext` / `Residents::CreateAuthorizedVisit` / `Visits::Create` unchanged.

**Non-Goals:**
- No visit listing/history endpoint (separate future change).
- No pending-visit (unauthorized) creation path.
- No caching or pagination of the units list in this first slice (a resident's eligible-unit count is expected to be small; add pagination later if that assumption breaks).

## Decisions

### 1. Resolve eligible units from `current_user.people`, never from a bare `Unit.find`

`User has_many :people, through: organization_memberships` — `people` is itself not tenant-scoped (it belongs to `User`, not to a request-scoped tenant), so `ActsAsTenant.without_tenant { current_user.people }` safely returns every `Person` row for this user across every organization, regardless of ambient tenant state. From there:

```ruby
ActsAsTenant.without_tenant do
  current_user.people.includes(unit_occupancies: :unit).flat_map do |person|
    person.unit_occupancies.active.map { |occ| [person.organization, occ.unit] }
  end
end
```

Each `(organization, unit)` pair is then filtered through `Authorization::Resolver.new(user:, organization:, unit:).allowed?(...)` for both `CREATE_VISITS` and `AUTHORIZE_VISITS` — the same two capabilities `Residents::VisitContext` already requires — evaluated inside `ActsAsTenant.with_tenant(organization)` per pair, since `Resolver` itself may touch `acts_as_tenant` models (roles, staff assignments). This guarantees the units list and the create endpoint use *exactly* the same eligibility rule, so nothing appears in the list that creation would then reject.

**Alternative considered**: query `Unit` directly with an `organization_id IN (current_user.organizations)` filter. Rejected — it still requires deriving the organization set safely first (same `without_tenant { current_user.organizations }` step), adds no simplification, and invites a future edit to accidentally drop the filter.

### 2. `Api::V1::Mobile::Units::VisitsController#create` resolves the unit's organization before loading the unit, not after

```ruby
def load_unit
  @unit = ActsAsTenant.without_tenant { Unit.find(params[:unit_id]) }
  organization = @unit.organization
  ActsAsTenant.current_tenant = organization  # or: wrap the remainder in with_tenant
end
```

Loading the unit itself must also happen with an explicit `without_tenant` block (not "no tenant set", which — per Context — is silently the same as unscoped, but making it explicit documents the intent and survives a future `require_tenant = true` flip without silently breaking). Membership is *not* yet verified at this point — the subsequent `Residents::VisitContext#authorized?` call is what verifies the requesting person actually has an active, capable relationship to this specific unit inside this specific organization. A user probing arbitrary unit IDs from other organizations gets the same `403 authorization_denied` the private endpoint already returns, since `VisitContext` calls `user.person_for(organization)`, which returns `nil` for an organization the user has no `Person` in.

**Risk**: between resolving `@unit.organization` and entering `ActsAsTenant.with_tenant`, no query has happened yet under the wrong tenant. The remainder of the action (`VisitContext`, `CreateAuthorizedVisit`) runs entirely inside `ActsAsTenant.with_tenant(organization) { ... }`, mirroring how `ApplicationController#set_current_organization` would have set it, just resolved per-request from the unit instead of from a subdomain.

### 3. Route shape mirrors the existing private nesting, under `mobile` instead of `private`

```ruby
namespace :mobile do
  namespace :auth do ... end
  get :me, to: "me#show"

  resources :units, only: [ :index ] do
    resources :visits, only: [ :create ], module: :units
  end
end
```

Same `resources :units { resources :visits, module: :units }` nesting `api/v1/private` already uses, so the controller namespace (`Api::V1::Mobile::Units::VisitsController`) and file layout (`app/controllers/api/v1/mobile/units/visits_controller.rb`) directly mirror `app/controllers/api/v1/private/units/visits_controller.rb` — a reviewer who knows the private endpoint can read the mobile one by difference alone.

### 4. Response payloads

- `GET /api/v1/mobile/units` → `{ data: [ { id, name, organization: { id, name } }, ... ] }`. Minimal identity only — no address/section detail, no capability flags (if it's in the list, both required capabilities are already true; nothing else reads this payload yet).
- `POST /api/v1/mobile/units/:unit_id/visits` → unchanged from the private endpoint: `{ data: { id, status } }`, `201`.

## Risks / Trade-offs

- **[Risk] `require_tenant` being off makes every future `acts_as_tenant` query in the mobile namespace a potential cross-tenant leak if a developer forgets to scope it.** → Mitigation: every mobile controller touching a tenant-scoped model must go through this change's pattern (`without_tenant` for user-owned lookups, `with_tenant(resolved_org)` for everything else). Flagging `ActsAsTenant.configure { |c| c.require_tenant = true }` as a follow-up hardening change is worth raising separately — out of scope here since it affects the admin/private surfaces too and needs its own review.
- **[Risk] N+1 `with_tenant` switches while building the units list (one per unit, to run `Resolver`).** → Acceptable at expected scale (single-digit units per resident); revisit if a resident with many units becomes real.
- **[Risk] Duplication between `Api::V1::Private::Units::VisitsController` and the new `Api::V1::Mobile::Units::VisitsController`** (both thin controllers with near-identical `create` bodies, differing only in tenant resolution). → Accepted for now, consistent with how `mobile-client-auth` duplicated rather than shared with `api/v1/auth`; a shared concern can be extracted later if a third caller appears.

## Open Questions

- Should the units list expose a unit `label`/section string beyond `name`, for disambiguating multiple units with the same name (the admin form's searchable-select already solves this on the admin side with secondary descriptive text)? Deferred — mirror that pattern if/when the mobile unit-picker UI needs it.
