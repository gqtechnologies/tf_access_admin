## ADDED Requirements

### Requirement: Authenticated user profile update endpoint
The system SHALL provide `PATCH /api/v1/mobile/me`, accepting `name`, `phone` (`{countryCode, number}` or `null`), `dateOfBirth`, `gender`, and optional multipart `avatar`, updating the authenticated user, and responding with the same shape as `GET /me`.

#### Scenario: Authenticated user updates their profile
- **WHEN** an authenticated user calls `PATCH /api/v1/mobile/me` with valid `name`, `phone`, `dateOfBirth`, and `gender`
- **THEN** the system responds `200 OK` with the updated `data.name`, `data.phone`, `data.dateOfBirth`, `data.gender`

#### Scenario: Explicit null phone clears stored phone
- **GIVEN** the user has a stored phone number
- **WHEN** `PATCH /api/v1/mobile/me` is called with `phone: null`
- **THEN** the response's `data.phone` is `null`

#### Scenario: Invalid gender is rejected
- **WHEN** `PATCH /api/v1/mobile/me` is called with a `gender` value outside `female`/`male`/`other`/`prefer_not_to_say`
- **THEN** the system responds `422 Unprocessable Entity`
- **AND** the user's stored gender is unchanged

#### Scenario: Avatar upload persists
- **WHEN** `PATCH /api/v1/mobile/me` is called as `multipart/form-data` with an `avatar` file
- **THEN** the file is attached to the user's `avatar`

### Requirement: Profile response includes phone, date of birth, and gender
The system SHALL include `phone`, `dateOfBirth`, and `gender` in `GET /api/v1/mobile/me`'s response, each `null` when not set.

#### Scenario: Unset fields render as null
- **GIVEN** a user with no stored phone, date of birth, or gender
- **WHEN** `GET /api/v1/mobile/me` is called
- **THEN** `data.phone`, `data.dateOfBirth`, and `data.gender` are all `null`
