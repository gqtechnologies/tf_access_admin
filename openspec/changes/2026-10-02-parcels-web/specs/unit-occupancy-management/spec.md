# unit-occupancy-management

## ADDED Requirements

### Requirement: Parcel withdrawal permission is managed with the occupancy
Creating or updating a unit occupancy SHALL accept `can_withdraw_parcels`, defaulting to false. The occupants table SHALL show whether each occupant may withdraw parcels, and changes to the permission SHALL be audited.

#### Scenario: Granting the permission
- **WHEN** an administrator edits an occupancy and enables "can withdraw parcels"
- **THEN** the occupancy is saved with the permission and the table shows it

#### Scenario: Revoking the permission
- **WHEN** the administrator disables it
- **THEN** the occupant can no longer be named in a parcel withdrawal

#### Scenario: New occupant
- **WHEN** an occupant is added without touching the option
- **THEN** the occupancy is created without the permission
