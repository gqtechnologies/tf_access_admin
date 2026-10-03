# mobile-private-api

## ADDED Requirements

### Requirement: Unit parcels endpoint for residents
`GET /api/v1/private/units/:unit_id/parcels` SHALL return, to a person with an active relationship with the unit, the unit's parcels still waiting (`received`) followed by those withdrawn in the last 30 days, newest first within each group. Each parcel SHALL carry `id`, `delivery_type`, `courier_company`, `tracking_code`, `notes`, `status`, `received_at`, `withdrawn_at`, `withdrawn_by_name` and `unit` (`id`, `name`). The response SHALL also carry `can_withdraw`, true when the requesting person may pick parcels up for that unit.

#### Scenario: Resident lists parcels
- **WHEN** a resident of the unit requests its parcels
- **THEN** the response is `200` with waiting parcels first and `can_withdraw` reflecting their occupancy

#### Scenario: No relationship with the unit
- **WHEN** the requester has no active occupancy or ownership of the unit
- **THEN** the response is `403`

#### Scenario: Unit of another organization
- **WHEN** the unit does not belong to the current organization
- **THEN** the response is `404`

### Requirement: Concierge parcel endpoints
Under `/api/v1/private/concierge`, an actor with `manage_parcels` on a property SHALL be able to: list its parcels with `GET parcels?property_id=&tab=&q=&page=` (`tab` is `received`, the default, or `withdrawn` for the last 30 days; `q` matches unit, courier or tracking code; the response includes `counters` and `pagination`); register one with `POST parcels` (`property_id`, `parcel[unit_id, delivery_type, courier_company, tracking_code, notes]`); read one with `GET parcels/:id`, including `eligible_withdrawers` (`id`, `name`, `avatar_url`); and register its withdrawal with `POST parcels/:id/withdraw` (`person_id`). `GET units?property_id=&q=` SHALL list the property's units (`id`, `name`) for the picker.

#### Scenario: Listing
- **WHEN** the concierge lists the parcels of an operated property
- **THEN** the response is `200` with only that property's parcels of the requested tab

#### Scenario: Property not operated
- **WHEN** `property_id` is missing or names a property where the actor lacks `manage_parcels`
- **THEN** the response is `403`

#### Scenario: Registration
- **WHEN** the concierge posts a valid parcel for a unit of the property
- **THEN** the response is `201` with the parcel

#### Scenario: Unit outside the property
- **WHEN** the posted `unit_id` does not belong to the property
- **THEN** the response is `404`

#### Scenario: Withdrawal
- **WHEN** the concierge posts `withdraw` with an eligible `person_id`
- **THEN** the response is `200` with the parcel as `withdrawn`

#### Scenario: Ineligible person or parcel already withdrawn
- **WHEN** the person is not eligible, or the parcel is not `received`
- **THEN** the response is `422` with a message naming the cause

#### Scenario: Parcel of another property
- **WHEN** the parcel belongs to a property the actor does not operate
- **THEN** the response is `404`
