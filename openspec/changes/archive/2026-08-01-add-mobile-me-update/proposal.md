## Why

The mobile app's profile-edit screen (`tf_access_mobile`'s `profile-edit.tsx`) already calls `PATCH /api/v1/mobile/me` with `name`, `phone`, `dateOfBirth`, `gender`, and an optional `avatar`, and has since it shipped — but the backend only ever implemented `GET /api/v1/mobile/me` (`email`/`name`/`dni`, per the archived `add-mobile-me-endpoint` change, which explicitly deferred phone/dateOfBirth/gender as future work). The `PATCH` route doesn't exist, so every save attempt 404s (confirmed in production logs: `Api::ErrorsController#not_found`). Additionally, `phone`, `date_of_birth`, and `gender` have no backing columns on `users` at all — only `avatar` (`has_one_attached`) already exists.

## What Changes

- Migration: add `phone_country_code:string`, `phone_number:string`, `date_of_birth:date`, `gender:string` to `users`.
- `Api::V1::Mobile::MeController#show`: response gains `phone` (`{countryCode, number}` or `null`), `dateOfBirth` (ISO date or `null`), `gender` (or `null`) — matching the shape `tf_access_mobile`'s `MeResponse` type already expects and defaults to `null` for.
- `Api::V1::Mobile::MeController#update` (new): accepts `name`, `phone[countryCode]`/`phone[number]`, `dateOfBirth`, `gender`, optional multipart `avatar`; updates `current_user`; renders the same shape as `#show`.
- `config/routes.rb`: add `patch :me, to: "me#update"` alongside the existing `get :me`.
- `gender` validated against the same four values the mobile client's `OptionSheet` offers (`female`, `male`, `other`, `prefer_not_to_say`) — invalid/unknown values rejected with `422`, not silently dropped.

## Capabilities

### Modified Capabilities
- `mobile-client-auth`: `GET /me` response shape extended (additive — existing consumers reading only `email`/`name`/`dni` are unaffected); new `PATCH /me` requirement added.

## Impact

- **DB**: new migration on `users` (4 nullable columns, no backfill needed — all `NULL` by default, matching how the mobile client already treats them as optional/absent).
- **Model**: `app/models/user.rb` — `gender` inclusion validation; no new associations (`avatar` already exists via `has_one_attached`).
- **Controller**: `app/controllers/api/v1/mobile/me_controller.rb`.
- **Routes**: `config/routes.rb`.
- **i18n**: new validation-error key for invalid `gender`.
- **No changes to `tf_access_mobile`** — it already sends the exact payload shape this implements; this change makes the backend match the client that's already shipped.

## Non-goals

- No email change endpoint (mobile's "Cambiar correo" row is already inert client-side, out of scope here).
- No avatar removal/reset endpoint — only replace-on-upload, matching current mobile UI (no "remove photo" affordance).
- No admin/Inertia-side exposure of these new fields — this is mobile-only, on the `User` record, unrelated to the tenant-scoped `Person` profile fields admins manage.
