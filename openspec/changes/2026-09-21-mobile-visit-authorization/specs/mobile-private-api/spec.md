# Mobile Private API

## ADDED Requirements

### Requirement: Visit authorization and rejection endpoints

The system SHALL expose `POST /api/v1/private/units/:unit_id/visits/:id/authorize` and `POST /api/v1/private/units/:unit_id/visits/:id/reject`, delegating to `Visits::Authorize` and `Visits::Reject` with the current user as actor, and returning `200` with the visit detail payload. The visit detail payload SHALL include `can_authorize` and `can_reject`, both `true` only while the visit is `pending`.

#### Scenario: Resident authorizes a pending visit

- **GIVEN** a `pending` visit of a unit on which the resident holds `authorize_visits`
- **WHEN** they POST authorize
- **THEN** the visit becomes `authorized` with the resident as `authorized_by`, and the response has `can_authorize: false`, `can_reject: false`, `can_cancel: true`

#### Scenario: Resident rejects a pending visit

- **WHEN** they POST reject on a `pending` visit
- **THEN** the visit becomes `rejected` and the response is `200`

#### Scenario: Visit already answered

- **GIVEN** a visit another resident already authorized or rejected
- **WHEN** authorize or reject is POSTed
- **THEN** the response is `422` with a localized error and the visit is unchanged

#### Scenario: No capability or out of reach

- **WHEN** the resident lacks `authorize_visits` on the unit, or the visit belongs to another unit or tenant
- **THEN** the response is `403` or `404` respectively
