# Mobile Private API

## ADDED Requirements

### Requirement: Visit detail endpoint

The system SHALL expose `GET /api/v1/private/units/:unit_id/visits/:id` returning `{ data: { id, status, effective_status, scheduled_at, valid_from, valid_until, checked_in_at, checked_out_at, visitor: { name, email, phone }, can_cancel, can_resend } }`. The visit MUST be resolved through the unit, itself resolved within the current tenant. The response MUST NOT include the visitor's identity document.

#### Scenario: Resident reads a visit of their unit

- **GIVEN** a resident with `authorize_visits` on unit U and an `authorized`, non-expired visit V of U
- **WHEN** they request the detail of V under U
- **THEN** the response is `200` with V's data, `can_cancel: true` and `can_resend: true`
- **AND** no document number appears in the body

#### Scenario: Visit from another unit or tenant

- **WHEN** the visit id belongs to a different unit or to another organization
- **THEN** the response is `404`

#### Scenario: Resident without capability

- **GIVEN** a resident whose occupancy of U has `can_authorize_visits = false`
- **WHEN** they request the detail
- **THEN** the response is `403`

#### Scenario: Flags follow the visit state

- **GIVEN** a `checked_in` visit
- **WHEN** the detail is requested
- **THEN** `can_cancel` and `can_resend` are `false`

### Requirement: Visit cancellation endpoint

The system SHALL expose `DELETE /api/v1/private/units/:unit_id/visits/:id`, cancelling the visit through `Visits::Cancel` with the current user as actor and returning `200 { data: { id, status: "cancelled" } }`.

#### Scenario: Resident cancels an authorized visit

- **GIVEN** an `authorized` visit of the resident's unit
- **WHEN** they send the DELETE
- **THEN** the visit becomes `cancelled`, a `cancelled` history event is recorded with the resident as actor, and the response is `200`

#### Scenario: Visit is no longer cancellable

- **GIVEN** a `checked_in`, `checked_out` or `cancelled` visit
- **WHEN** the DELETE is sent
- **THEN** the response is `422` with a localized error and the visit is unchanged

### Requirement: Resend visitor invitation endpoint

The system SHALL expose `POST /api/v1/private/units/:unit_id/visits/:id/resend_invitation`, returning `200` with the visit detail payload on success.

#### Scenario: Successful resend

- **GIVEN** an `authorized`, non-expired visit with no resend in the last 5 minutes
- **WHEN** the resident sends the POST
- **THEN** the visitor is notified again, the response is `200` and `can_resend` is `false`

#### Scenario: Visit not resendable

- **GIVEN** a visit that is not `authorized`, or whose `valid_until` has passed
- **WHEN** the POST is sent
- **THEN** the response is `422` with a localized error and nothing is sent

#### Scenario: Cooldown

- **GIVEN** the invitation was resent 2 minutes ago
- **WHEN** the POST is sent again
- **THEN** the response is `429` with a `Retry-After` header in seconds and nothing is sent
