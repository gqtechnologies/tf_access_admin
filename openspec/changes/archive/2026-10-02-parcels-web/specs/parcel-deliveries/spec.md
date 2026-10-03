# parcel-deliveries

## ADDED Requirements

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
