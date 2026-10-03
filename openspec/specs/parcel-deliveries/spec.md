# parcel-deliveries Specification

## Purpose
Registers the parcels and deliveries that arrive at a property's front desk for a unit, tells the unit's residents, and records who picked each one up.

## Requirements

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

### Requirement: Web front desk lists a property's parcels
`GET /concierge/parcels` SHALL render, for an actor holding `manage_parcels`, the parcels of one operated property: those waiting by default, or those withdrawn in the last 30 days, with counters for both, text search over unit, courier and tracking code, and pagination. The property SHALL be the one named by `property_id` when the actor operates it, otherwise the first operated property. Waiting parcels SHALL carry the residents allowed to withdraw them.

#### Scenario: Concierge opens the list
- **WHEN** a concierge opens the page
- **THEN** the waiting parcels of the assigned property are listed with both counters

#### Scenario: Property not operated
- **WHEN** `property_id` names a property the actor does not operate
- **THEN** the actor's first operated property is shown instead

#### Scenario: Actor with several properties
- **WHEN** the actor operates more than one property
- **THEN** the page offers a property selector listing all of them

#### Scenario: Actor without the capability
- **WHEN** a user without `manage_parcels` requests the page
- **THEN** the user is redirected away

### Requirement: Web front desk registers arrivals and withdrawals
`POST /concierge/parcels` SHALL register an arrival for a unit of the active property through the same rules as the API, and `POST /concierge/parcels/:id/withdraw` SHALL register a withdrawal by the named resident. Both SHALL redirect to the list; a rejection SHALL come back as page errors without changing any data.

#### Scenario: Arrival registered
- **WHEN** the form is submitted with a unit of the property
- **THEN** the parcel is stored, the unit is notified and the list is shown again

#### Scenario: Unit missing or from another property
- **WHEN** the unit is blank or does not belong to the active property
- **THEN** nothing is stored and an error is shown

#### Scenario: Withdrawal registered
- **WHEN** a resident with the withdrawal permission is chosen
- **THEN** the parcel becomes withdrawn by that person

#### Scenario: Withdrawal rejected
- **WHEN** the person is not eligible, the parcel was already withdrawn, or it belongs to a property the actor does not operate
- **THEN** the parcel is unchanged and an error is shown
