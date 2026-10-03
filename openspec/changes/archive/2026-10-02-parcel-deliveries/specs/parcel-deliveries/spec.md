# parcel-deliveries

## Purpose

Registers the parcels and deliveries that arrive at a property's front desk for a unit, tells the unit's residents, and records who picked each one up.

## ADDED Requirements

### Requirement: Parcel arrival is registered by front-desk staff
An actor holding `manage_parcels` on a unit's property SHALL be able to register a parcel for that unit with a delivery type and optional courier, tracking code and notes. The parcel SHALL start in status `received`, stamped with the arrival time and the person who received it, and a status history entry SHALL be recorded.

#### Scenario: Concierge registers a parcel
- **WHEN** a concierge of the property registers a parcel for a unit
- **THEN** the parcel is stored as `received` with `received_at`, `received_by_person` and a history entry to `received`

#### Scenario: Actor without the capability
- **WHEN** someone without `manage_parcels` on the property tries to register a parcel
- **THEN** the registration is rejected and nothing is stored

#### Scenario: Invalid delivery type
- **WHEN** the delivery type is not one of `parcel`, `food`, `document`, `groceries`, `other`
- **THEN** the registration is rejected as invalid

### Requirement: The whole unit is notified of an arrival
Registering a parcel SHALL create a `parcel` push notification for every person with a currently valid active occupancy or ownership of the unit, once per person, and SHALL stamp `notified_at` when at least one notification was created. A failure to notify SHALL NOT undo the registration.

#### Scenario: Unit with several residents
- **WHEN** a parcel is registered for a unit with two occupants and one owner
- **THEN** three notifications are created and queued for delivery

#### Scenario: Unit without residents
- **WHEN** the unit has no active occupancy or ownership
- **THEN** the parcel is registered, no notification is created and `notified_at` stays empty

### Requirement: Withdrawal requires a resident with the withdrawal permission
A `received` parcel SHALL be withdrawn only by naming a person who holds a currently valid active occupancy of the parcel's unit with `can_withdraw_parcels`. The withdrawal SHALL set status `withdrawn`, the withdrawal time and that person, and record a history entry. Only an actor holding `manage_parcels` on the property SHALL register it.

#### Scenario: Permitted resident picks up
- **WHEN** the concierge registers the withdrawal naming an occupant with `can_withdraw_parcels`
- **THEN** the parcel becomes `withdrawn` with `withdrawn_at` and `withdrawn_by_person`

#### Scenario: Resident without the permission
- **WHEN** the named person occupies the unit without `can_withdraw_parcels`, or has no active occupancy of it
- **THEN** the withdrawal is rejected and the parcel stays `received`

#### Scenario: Already withdrawn
- **WHEN** the parcel is already `withdrawn`
- **THEN** the withdrawal is rejected

### Requirement: Front-desk role holds the parcel capability
The `concierge` and `property_admin` operational roles SHALL include `manage_parcels`, scoped to their assigned properties.

#### Scenario: Concierge of another property
- **WHEN** a concierge assigned to property P acts on a parcel of property Q
- **THEN** the action is not authorized
