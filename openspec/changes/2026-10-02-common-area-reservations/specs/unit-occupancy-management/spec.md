# unit-occupancy-management

## ADDED Requirements

### Requirement: Common area reservation permission is managed with the occupancy
Creating or updating a unit occupancy SHALL accept `can_reserve_common_areas`, defaulting to false. The occupants table SHALL show it, and changes SHALL be audited.

#### Scenario: Granting the permission
- **WHEN** an administrator enables "can reserve common areas" on an occupancy
- **THEN** the occupant can book common areas for that unit
