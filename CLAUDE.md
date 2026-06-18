# tf_access_admin

Multi-tenant residential property & visit management platform. Ruby on Rails backend rendering Vue 3 pages through Inertia.

## Stack

- Ruby 3.3.6, Rails ~> 8.1
- Inertia (`inertia_rails`) + Vue 3 (`@inertiajs/vue3`), Composition API + `<script setup>` + TypeScript
- Vite (`vite-plugin-ruby`) for assets, source dir `app/javascript`
- Tailwind CSS v4, reka-ui / shadcn-vue components
- Sidekiq for background jobs
- `acts_as_tenant` for multitenancy, Pundit for authorization, Rolify for roles, `audited` for audit trails
- Minitest for tests, RuboCop (rails-omakase) for Ruby style, Brakeman + bundler-audit for security

## Commands

```bash
bin/dev                 # start web (Rails), vite, and sidekiq (Procfile.dev)
bin/rails s             # Rails server only
bin/vite dev            # Vite dev server only

bin/rails test                       # full Ruby test suite
bin/rails test test/path/to_test.rb  # single file
bin/rails test test/path/to_test.rb:42  # single test by line
bin/rails test:system                # system tests

bin/rubocop             # Ruby style
npm run check           # vue-tsc + tsc type checking
npm run build           # production asset build

bin/ci                  # full CI pipeline (setup, rubocop, audits, brakeman, tests, seeds)
bin/brakeman --quiet --no-pager   # security scan
bin/bundler-audit       # gem vulnerability audit
```

## Layout

- `app/models/` — domain models; concerns in `app/models/concerns/`
- `app/policies/` — Pundit policies (capability-based; see Authorization below)
- `app/services/` — service objects / use cases (e.g. `Authorization::*`, `People::*`, `OperationalRoles::*`)
- `app/serializers/` — props/contracts sent to the frontend
- `app/controllers/` — thin controllers, render Inertia pages
- `app/javascript/pages/` — Inertia page components (Vue)
- `app/javascript/components/`, `layouts/`, `lib/` — shared frontend code
- `test/` — Minitest mirrors `app/` structure; shared helpers in `test/support/`
- `openspec/` — OpenSpec change proposals, specs, and task lists

## Core domains

Organizations · Residential Properties · Property Sections · Units · Persons · Unit Ownerships · Unit Occupancies · Staff Assignments · Visits (future) · Bulk Imports · Authentication & Authorization · Auditing

## Conventions

### Multitenancy (strict)
- Every tenant-scoped model belongs to `organization`; never query tenant records globally.
- Scope through `Current.organization` / `current_organization` or an explicit parent resource — not raw `Model.find(params[:id])`.
- Policies enforce tenant isolation. No cross-organization access, even for admins.
- Tenant-scoped uniqueness indexes must include `organization_id`.

### Rails
- Prefer Rails conventions before custom abstractions; keep controllers thin.
- Business logic in service objects / use cases, not controllers.
- Strong params, model validations, and DB constraints where integrity matters.
- Prefer `normalizes` for simple input normalization.
- Prefer soft delete / validity periods (`status`, `starts_at`, `ends_at`) over hard deletes for historical data.
- Add indexes for FKs and frequent lookups. Maintain auditability (`audited`) for ownership, occupancy, and staff/role changes.
- Write tests for policies, services, and critical model rules. When adding a CRUD, mirror an existing one (e.g. `ResidentialProperty`).

### Authorization (capability-based)
- `Authorization::Resolver` is the single source of effective capabilities; it always starts from `User`, never directly from `Person`.
- Capabilities live in `Authorization::Capabilities`; role→capability maps and staff-type normalization in `Authorization::StaffRoleMapper`.
- Organizational roles (`tenant_admin`, `content_manager`) are org-wide; property roles (`property_admin`, `concierge`, `cleaning_staff`, `internal_staff`) are always scoped per `residential_property_id` and derived from active `StaffAssignment`.
- Owner/resident capabilities derive from active `UnitOwnership` / `UnitOccupancy`.
- Policies call `allowed?(capability)` / `can?` via `ApplicationPolicy`, not hard-coded role strings or only `admin?`.

### Vue / Inertia
- Composition API with `<script setup>` and typed props.
- Props from Rails must be explicit and minimal; keep authorization/scoping in Rails.
- Reuse existing components, layouts, shared props, pagination/filter/sort patterns before creating new ones.
- Do not duplicate business rules in Vue; do not introduce new UI libraries unless requested.
- Follow `.agents/skills/vue-best-practices/SKILL.md` and `.agents/skills/rails-expert/SKILL.md`.

### i18n (required for ALL user-facing text)
- Every user-facing string MUST be internationalized. Never hardcode literal text in views, components, serializers, flash messages, validations, or emails.
- Supported locales live in `config/locales/` (`es`, `en`, `pt`; plus `devise.*`). Add a key to every locale file when introducing a new string.
- Rails: use `I18n.t` / `t(".key")`; rely on locale YAML and Rails conventions for model/attribute names and error messages.
- Vue: use `vue-i18n` via `const { t } = useI18n()` and `t('some.key')` / `{{ t('some.key') }}`. Do not inline literal strings in templates.
- Frontend translations are sourced from Rails and passed to `vue-i18n` through Inertia shared props (`app.locale`, `app.translations`) in `app/javascript/entrypoints/inertia.ts`. Add frontend-facing keys to the Rails locale files so they reach both sides; keep `fallbackLocale: 'en'` populated.
- Use nested, namespaced keys mirroring the feature (e.g. `admin.sidebar.operational_roles`). Use interpolation/pluralization instead of string concatenation.

## Workflow

- Follow the OpenSpec workflow for non-trivial changes (`openspec/` + `.claude/skills/openspec-*`). Implement tasks from the change's `tasks.md`; mark `- [ ]` → `- [x]` as each completes; keep changes minimal and scoped.
- Load the relevant skill before implementing (Rails / Vue / OpenSpec).
- Do not produce implementation summaries or change logs unless explicitly requested.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
