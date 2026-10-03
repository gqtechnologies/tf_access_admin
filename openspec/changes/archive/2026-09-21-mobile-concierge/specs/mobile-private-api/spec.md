# Mobile Private API

## ADDED Requirements

### Requirement: Concierge properties endpoint

The system SHALL expose `GET /api/v1/private/concierge/properties` returning `{ data: [{ id, name }] }` with the residential properties of the current tenant on which the current user holds `view_authorized_visits`, ordered by name.

#### Scenario: Concierge lists their properties

- **GIVEN** a user with an active concierge assignment on property P
- **WHEN** they request the endpoint
- **THEN** the response is `200` and contains only P

#### Scenario: Resident gets an empty list

- **GIVEN** a resident without staff assignments
- **WHEN** they request the endpoint
- **THEN** the response is `200` with an empty `data`

### Requirement: Concierge operational visit listing

The system SHALL expose `GET /api/v1/private/concierge/visits` requiring `property_id`, accepting `tab` (`authorized` default, `checked_in`, `checked_out`), `q` and `page`, and returning `{ data, counters: { authorized, checked_in, checked_out }, pagination }`. Results MUST be limited to the policy scope and to that single property. Each entry SHALL expose `id`, `status`, `effective_status`, `scheduled_at`, `checked_in_at`, `checked_out_at`, `visitor.name`, `unit.display_name`, `authorized_by_name`, `can_check_in`, `can_check_out`, and MUST NOT expose the visitor's email, phone or document.

#### Scenario: Listing by tab

- **GIVEN** property P with one `authorized` and one `checked_in` visit
- **WHEN** the concierge of P requests `tab=checked_in`
- **THEN** only the `checked_in` visit is returned and `counters` reports `authorized: 1, checked_in: 1`

#### Scenario: Property outside the assignment

- **WHEN** the concierge of P requests `property_id` of property Q, or omits `property_id`
- **THEN** the response is `403`

#### Scenario: No cross-property leakage

- **GIVEN** an `authorized` visit on property Q
- **WHEN** the concierge of P lists P's visits
- **THEN** that visit is not returned nor counted

#### Scenario: Search

- **WHEN** the concierge sends `q` with part of a visitor's name
- **THEN** only matching visits of the requested tab are returned

#### Scenario: Minimal visitor data

- **WHEN** a listing is returned
- **THEN** the body contains no visitor email, phone or document number

### Requirement: Concierge check-in and check-out endpoints

The system SHALL expose `POST /api/v1/private/concierge/visits/:id/check_in` (optional `check_in.vehicle_plate`, `check_in.notes`) and `POST /api/v1/private/concierge/visits/:id/check_out` (optional `check_out.notes`), delegating to `Visits::CheckIn` and `Visits::CheckOut` with the current user as actor, and returning `200` with the updated visit entry.

#### Scenario: Check-in

- **GIVEN** an `authorized`, non-expired visit on the concierge's property
- **WHEN** they POST check_in with a vehicle plate
- **THEN** the visit becomes `checked_in`, the plate is stored in its operational metadata, and the entry returns `can_check_in: false, can_check_out: true`

#### Scenario: Check-out

- **GIVEN** a `checked_in` visit
- **WHEN** the concierge POSTs check_out
- **THEN** the visit becomes `checked_out` and the response is `200`

#### Scenario: Invalid transition

- **WHEN** check_in is sent for a `cancelled` visit, or check_out for an `authorized` one
- **THEN** the response is `422` with a localized error and the visit is unchanged

#### Scenario: Visit out of reach

- **WHEN** the visit belongs to a property or organization the user cannot operate
- **THEN** the response is `404`

#### Scenario: Resident cannot operate

- **WHEN** a resident without staff assignment POSTs check_in on a visit of their own unit
- **THEN** the response is `403` or `404` and the visit is unchanged
