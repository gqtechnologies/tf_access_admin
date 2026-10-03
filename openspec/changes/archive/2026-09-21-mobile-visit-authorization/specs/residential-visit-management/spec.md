# Residential Visit Management

## ADDED Requirements

### Requirement: Pending visits can be rejected

The system SHALL support rejecting a `pending` visit through `Visits::Reject`, moving it to `rejected` and recording a `rejected` history event with the actor. Rejection SHALL require the same capability as authorization (`authorize_visits` or `manage_visits`) and MUST NOT be possible from any status other than `pending`.

#### Scenario: Rejection records history

- **WHEN** a resident rejects a pending visit
- **THEN** the visit is `rejected` and its history gains a `rejected` event from `pending` with the resident as actor

#### Scenario: Non-pending visit

- **WHEN** rejection is attempted on an `authorized` visit
- **THEN** it fails and the visit is unchanged

#### Scenario: Rejected visits are not operational

- **WHEN** a visit is `rejected`
- **THEN** it does not appear in concierge operational listings and cannot be checked in

### Requirement: Visitor is notified when a resident authorizes from the app

When a pending visit is authorized through the private API, the system SHALL notify the visitor through `Visits::NotifyVisitor` if the visitor person has a linked user or a contact email. A notification failure MUST NOT affect the authorization. Rejection MUST NOT notify the visitor.

#### Scenario: Visitor with email

- **WHEN** a resident authorizes a pending visit whose visitor has a contact email
- **THEN** the invitation email is enqueued

#### Scenario: Visitor without contact data

- **WHEN** the visitor has neither a linked user nor an email
- **THEN** the visit is authorized and nothing is sent

#### Scenario: Rejection is silent

- **WHEN** a resident rejects a pending visit
- **THEN** nothing is sent to the visitor
