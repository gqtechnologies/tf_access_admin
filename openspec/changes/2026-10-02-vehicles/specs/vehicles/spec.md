# vehicles

## Purpose

Keeps the register of the vehicles that belong to each unit so the front desk can tell whose vehicle is at the gate.

## ADDED Requirements

### Requirement: Residents register their unit's vehicles
A person holding a currently valid occupancy or ownership of a unit SHALL be able to list, register and remove the unit's vehicles. A vehicle SHALL have a plate (stored uppercase without spaces or symbols, up to 12 characters) and optional type, brand, model and color. A plate SHALL be unique among the organization's active vehicles.

#### Scenario: Registration
- **WHEN** a resident registers plate "ab-cd 12"
- **THEN** it is stored as "ABCD12" for the unit, attributed to them

#### Scenario: Duplicate plate
- **WHEN** another vehicle of the organization already has that plate
- **THEN** the registration is rejected with `422`

#### Scenario: No relationship with the unit
- **WHEN** someone without a relationship with the unit requests its vehicles
- **THEN** the response is `404`

### Requirement: The front desk looks up plates
`GET /api/v1/private/concierge/vehicles?property_id=&plate=` SHALL return, to an actor operating the property, up to 20 active vehicles of that property whose plate contains the normalized text, with unit and owner. A blank plate SHALL return nothing.

#### Scenario: Partial plate
- **WHEN** the concierge types "cd-1"
- **THEN** vehicles of the property whose plate contains "CD1" are returned and vehicles of other properties are not

### Requirement: The administration keeps the register
The administration page SHALL list a property's active vehicles with plate, vehicle details, unit and owner, searchable by plate, and SHALL allow removing one.

#### Scenario: Removal
- **WHEN** an administrator removes a vehicle
- **THEN** it no longer appears at the front desk or in the unit's list
