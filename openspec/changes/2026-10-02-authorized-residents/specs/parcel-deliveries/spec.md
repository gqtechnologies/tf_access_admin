# parcel-deliveries

## ADDED Requirements

### Requirement: Authorized people may withdraw parcels
An approved, currently valid authorized person of the parcel's unit with `can_withdraw_parcels` SHALL be eligible to withdraw its parcels, in addition to the occupants with that permission.

#### Scenario: Nanny picks up
- **WHEN** the front desk registers a withdrawal naming an approved authorized person with the parcel permission
- **THEN** the withdrawal is accepted

#### Scenario: Expired authorization
- **WHEN** the authorization has ended
- **THEN** the person is no longer eligible
