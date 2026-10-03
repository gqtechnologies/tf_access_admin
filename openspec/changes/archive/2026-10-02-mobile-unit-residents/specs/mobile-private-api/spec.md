# mobile-private-api

## ADDED Requirements

### Requirement: Unit residents endpoint
`GET /api/v1/private/units/:unit_id/residents` SHALL return one entry per person holding a currently valid active occupancy or ownership of the unit. Each entry SHALL carry `id`, `name`, `avatar_url` (or `null`), `relationships` (`"owner"` for an ownership and the occupancy type for an occupancy, without duplicates), `can_authorize_visits` and `is_me`. The entry of the requesting user SHALL come first and the rest SHALL be ordered by name. The payload SHALL NOT include email, phone or document.

#### Scenario: Resident lists the unit
- **WHEN** a member with an active occupancy of the unit requests its residents
- **THEN** the response is `200` with every person with an active relationship, the requester first with `is_me: true`

#### Scenario: Person who owns and occupies
- **WHEN** a person has both an active ownership and an active occupancy of the unit
- **THEN** that person appears once with both relationships

#### Scenario: Ended or inactive relationships
- **WHEN** an occupancy or ownership has ended, has not started, or is not active
- **THEN** it does not contribute to the list

#### Scenario: Visit authorization flag
- **WHEN** a person's active occupancy has `can_authorize_visits`
- **THEN** the entry has `can_authorize_visits: true`; an owner without such an occupancy has `false`

### Requirement: Unit residents are visible only to the unit's own residents
The endpoint SHALL require authentication and an active relationship between the requesting person and the unit.

#### Scenario: No relationship with the unit
- **WHEN** a member of the organization without an active occupancy or ownership of the unit requests its residents
- **THEN** the response is `403`

#### Scenario: Unit of another organization
- **WHEN** the unit does not belong to the current organization
- **THEN** the response is `404`

#### Scenario: Unauthenticated
- **WHEN** the request carries no valid token
- **THEN** the response is `401`
