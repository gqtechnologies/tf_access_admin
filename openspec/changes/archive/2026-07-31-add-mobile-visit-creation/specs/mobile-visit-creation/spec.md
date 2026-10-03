## ADDED Requirements

### Requirement: Mobile units listing is scoped to the user's own capable relationships
The system SHALL provide `GET /api/v1/mobile/units`, returning, across all organizations the authenticated user belongs to, only the units where the user holds both `create_visits` and `authorize_visits` capability. The endpoint SHALL NOT resolve or require a tenant/organization from the request; organization scope is derived entirely from the authenticated user's own relationships.

#### Scenario: Resident with a single eligible unit
- **GIVEN** an authenticated user has an active `UnitOccupancy` on unit U in organization O with `can_authorize_visits: true`
- **WHEN** the user calls `GET /api/v1/mobile/units`
- **THEN** the response includes U with its organization O

#### Scenario: Unit without authorize capability is excluded
- **GIVEN** an authenticated user has an active `UnitOccupancy` on unit U with `can_authorize_visits: false`
- **WHEN** the user calls `GET /api/v1/mobile/units`
- **THEN** U is not included in the response

#### Scenario: Units across multiple organizations are all returned
- **GIVEN** an authenticated user has eligible units in organization O1 and organization O2
- **WHEN** the user calls `GET /api/v1/mobile/units`
- **THEN** the response includes eligible units from both O1 and O2
- **AND** each unit entry identifies its organization

#### Scenario: User with no eligible units gets an empty list
- **GIVEN** an authenticated user has no active `UnitOccupancy` granting both required capabilities
- **WHEN** the user calls `GET /api/v1/mobile/units`
- **THEN** the response is `200 OK` with an empty `data` array

### Requirement: Mobile visit creation is unit-scoped and organization-safe without a request tenant
The system SHALL provide `POST /api/v1/mobile/units/:unit_id/visits`, creating a visit in `authorized` status for the given unit, using the same authorization rule as `GET /api/v1/mobile/units` (`create_visits` AND `authorize_visits` on that unit). The system SHALL resolve the unit's organization from the unit itself and SHALL NOT trust, require, or infer an organization from the request subdomain or headers.

#### Scenario: Authorized user creates a visit for their own unit
- **GIVEN** an authenticated user has `create_visits` and `authorize_visits` on unit U in organization O
- **WHEN** the user calls `POST /api/v1/mobile/units/:unit_id/visits` with valid visitor and schedule data for U
- **THEN** the response is `201 Created`
- **AND** the visit is persisted with status `authorized`, organization O, and unit U

#### Scenario: User without a relationship to the unit's organization is denied
- **GIVEN** an authenticated user has no `Person` record in organization O
- **AND** unit U belongs to organization O
- **WHEN** the user calls `POST /api/v1/mobile/units/:unit_id/visits` for U
- **THEN** the response is `403 Forbidden`
- **AND** no visit is persisted

#### Scenario: User with a relationship in the organization but not on this unit is denied
- **GIVEN** an authenticated user has an active `Person`/`UnitOccupancy` in organization O on a different unit
- **AND** unit U also belongs to organization O
- **WHEN** the user calls `POST /api/v1/mobile/units/:unit_id/visits` for U
- **THEN** the response is `403 Forbidden`
- **AND** no visit is persisted

#### Scenario: Invalid visitor or schedule data is rejected
- **GIVEN** an authenticated user is authorized on unit U
- **WHEN** the user calls `POST /api/v1/mobile/units/:unit_id/visits` with missing or invalid visitor/schedule data
- **THEN** the response is `422 Unprocessable Entity`
- **AND** no visit is persisted

### Requirement: Mobile visit endpoints require authentication
The system SHALL require a valid authenticated user (mobile JWT) for both `GET /api/v1/mobile/units` and `POST /api/v1/mobile/units/:unit_id/visits`.

#### Scenario: Unauthenticated request is rejected
- **WHEN** either endpoint is called with no `Authorization` header, or an invalid/expired JWT
- **THEN** the system responds `401 Unauthorized`
