## Context

`tf_access_mobile`'s `src/api/auth.ts#updateMe` sends `PATCH {baseUrl}/me` as JSON normally, or `multipart/form-data` when an avatar is picked (`name`, `dateOfBirth`, `gender`, `phone[countryCode]`, `phone[number]`, `avatar` file). `users` table has `has_one_attached :avatar` already (used nowhere yet) but no `phone`/`date_of_birth`/`gender` columns — the archived `add-mobile-me-endpoint` change deliberately scoped `GET /me` to `email`/`name`/`dni` only and deferred the rest.

## Goals / Non-Goals

**Goals:** `PATCH /me` accepts and persists everything the shipped mobile client already sends; `GET /me` reflects it back in the same shape the client already parses (`normalizeMeResponse` treats missing/invalid `phone`/`dateOfBirth`/`gender` as `null`, so partial data never breaks the client).

**Non-Goals:** email change, avatar removal, admin-side exposure (see proposal.md).

## Decisions

### 1. Plain columns on `users`, not `metadata` jsonb

`User#metadata` exists but is untyped/unindexed and unused elsewhere on this model for structured profile fields; `phone_country_code`/`phone_number`/`date_of_birth`/`gender` are exactly the kind of typed, individually-nullable fields plain columns suit better (matches how `Person` already has a real `birthdate:date` column rather than stuffing it in metadata).

### 2. `phone_country_code`/`phone_number` as two columns, not one

Mirrors the wire shape (`phone: {countryCode, number}`) exactly — no parsing/formatting logic needed in either direction. Both nullable; `phone` in the JSON response is `null` unless *both* are present (a country code with no number isn't a usable phone).

### 3. `#update` strong params and gender validation

```ruby
def update
  attrs = me_params
  if current_user.update(attrs)
    render json: show_payload, status: :ok
  else
    render json: { error: current_user.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end
end

private

def me_params
  params.permit(:name, :dateOfBirth, :gender, :avatar, phone: %i[countryCode number]).then do |p|
    {
      name: p[:name],
      date_of_birth: p[:dateOfBirth].presence,
      gender: p[:gender].presence,
      phone_country_code: p.dig(:phone, :countryCode),
      phone_number: p.dig(:phone, :number),
      avatar: p[:avatar]
    }.compact
  end
end
```

`gender` gets `validates :gender, inclusion: { in: %w[female male other prefer_not_to_say] }, allow_nil: true` on `User` — matches the mobile client's fixed `GENDER_OPTIONS` exactly, so a client-originated value can never fail this, only a malformed/forged request.

### 4. `phone: nil` (explicit JSON `null`) clears both phone fields

The mobile client always sends `phone: fields.phone` where `fields.phone` is `null` when the number field is empty (`profile-edit.tsx`: `phone: phoneNumber.trim() ? {...} : null`) — so an explicit `null` must clear stored phone, not be ignored. `params.permit(phone: ...)` on a JSON body with `"phone": null` yields `phone` absent from the permitted hash in Rails' default handling; the controller reads `params[:phone]` presence *before* permitting to distinguish "key present with null" (clear) from "key absent" (leave untouched — relevant if a future caller sends partial updates, even though today's client always sends the full form).

## Risks / Trade-offs

- **[Risk] New nullable columns are just additive** — no migration risk beyond the standard `add_column` (no default, no backfill, near-instant on Postgres).
- **[Risk] Multipart avatar parsing already works** (`has_one_attached`); untested path here is the JSON-vs-multipart branch in the mobile client's own request builder, already shipped and unrelated to this change.

## Open Questions

None.
