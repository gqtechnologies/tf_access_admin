# authorized-residents

## Purpose

Lets a unit name people who don't live there — nannies, drivers, relatives — to come in without an invitation and optionally pick up the unit's parcels, once the administration approves them.

## ADDED Requirements

### Requirement: Residents propose authorized people
A person holding a currently valid occupancy of the unit with `can_authorize_visits`, or a currently valid ownership of it, SHALL be able to propose an authorized person with name, email, optional document and phone, relationship, optional end date (valid through that day in the property's time zone) and whether they may withdraw parcels. The person SHALL be resolved or created by email like a visitor. The proposal SHALL be pending and SHALL NOT be accepted when that person already has a pending or approved authorization for the unit.

#### Scenario: Proposal
- **WHEN** an occupant who authorizes visits proposes a nanny
- **THEN** a pending authorization is stored, attributed to them

#### Scenario: Not allowed to propose
- **WHEN** an occupant without the visit permission proposes someone
- **THEN** the proposal is rejected with `403`

#### Scenario: Duplicate
- **WHEN** the same person is proposed again while their authorization is open
- **THEN** the proposal is rejected

### Requirement: The administration decides
An actor holding `manage_occupancies` on the unit's property SHALL be able to approve or reject a pending authorization and revoke an approved one, which ends it now. Each decision SHALL notify the resident who proposed it with an `authorized_person` push. Residents who may propose SHALL be able to withdraw a pending or approved authorization of their unit.

#### Scenario: Approval
- **WHEN** an administrator approves a pending authorization
- **THEN** it becomes active and the proposer is notified

#### Scenario: Invalid transition
- **WHEN** an administrator tries to revoke a rejected authorization
- **THEN** it is refused and nothing changes

### Requirement: Approved people are known at the front desk
`GET /api/v1/private/concierge/authorized_people?property_id=&q=` SHALL return, to an actor operating the property, the approved authorizations that are currently valid (started and not ended), with name, document, relationship, unit, validity and whether they may withdraw parcels, filtered by `q` against the name, the unit or, exactly, the document.

#### Scenario: Pending or expired
- **WHEN** an authorization is pending, rejected, revoked or past its end
- **THEN** it is not listed

#### Scenario: Not a concierge
- **WHEN** a resident requests the list
- **THEN** the response is `403`
