# lease-contracts

## Purpose

Records the leases of a property's units and lets each lease drive its tenant's occupancy, from activation to termination.

## ADDED Requirements

### Requirement: Administrators register leases as drafts
An actor holding `manage_occupancies` on a property SHALL be able to register a lease for one of its units with the tenant's name and email (and optional document and phone), an optional landlord who must be a current owner of the unit, a start date, an optional end date and the tenant's permissions, which default to granted. The lease SHALL start as a draft and create no occupancy.

#### Scenario: Draft
- **WHEN** an administrator registers a lease naming a current owner as landlord
- **THEN** it is stored as a draft for that unit

#### Scenario: Landlord who is not an owner
- **WHEN** the landlord is not a current owner of the unit
- **THEN** nothing is stored and an error is shown

### Requirement: Activating a lease creates the tenant's occupancy
Activating a draft lease SHALL create an active `tenant` occupancy of the unit for the tenant, from the lease's start to the end of its end date in the property's time zone, with the lease's permissions and the lease as its source, and SHALL mark the lease active. Activating a lease that is not a draft SHALL be refused.

#### Scenario: Activation
- **WHEN** an administrator activates a draft lease
- **THEN** the tenant has a current occupancy with the lease's permissions

#### Scenario: Activating twice
- **WHEN** an already active lease is activated again
- **THEN** it is refused and no second occupancy is created

### Requirement: Terminating a lease closes the occupancy
Terminating an active lease SHALL set its end date to the chosen date (today by default, never before its start), record who terminated it, mark it terminated and end the tenant's occupancy at the end of that day.

#### Scenario: Termination today
- **WHEN** an administrator terminates an active lease without choosing a date
- **THEN** the lease ends today and the occupancy ends at the end of today
