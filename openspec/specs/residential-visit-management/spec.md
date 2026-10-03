# residential-visit-management Specification

## Purpose

Lets residents register, answer and manage the visits of their own units through the private API, with the visitor kept as a canonical person and authorization tied to the unit relationship.

## Requirements

### Requirement: Resident registers a visit through a private authenticated API

The system SHALL provide a private authenticated API contract, distinct from the administrative visit flow, through which a resident submits a unit, visitor name, visitor email, optional visitor document, optional visitor phone, and visit date/time.

#### Scenario: Authenticated resident submits a valid private request

- **GIVEN** a `User` is authenticated in organization O
- **AND** the user's `Person` has an active relationship with unit U in O
- **AND** the user is allowed to create and authorize visits for U
- **WHEN** the user submits a visitor name, a valid visitor email and a visit date/time through the private API
- **THEN** the system creates a visit for U
- **AND** the operation does not use an admin visit screen or admin Inertia flow

#### Scenario: Missing or invalid visitor email is rejected

- **WHEN** the resident submits a visitor without email, or with a malformed email
- **THEN** the system returns `422` with a localized error
- **AND** no `Person` or `Visit` is persisted

#### Scenario: Unauthenticated request is rejected

- **GIVEN** no valid private API authentication is present
- **WHEN** a visit registration is submitted
- **THEN** the request is rejected
- **AND** no `Person`, `Visit`, or functional history record is persisted

### Requirement: Resident visit registration is separate from administration

The system SHALL keep resident private API registration separate from administrative visit management. This capability SHALL NOT require or create admin views, resident admin Vue screens, or a complete mobile resident portal.

#### Scenario: Private flow does not depend on admin UI

- **GIVEN** the resident registration capability is implemented
- **WHEN** a resident creates a visit through the private API
- **THEN** no administrative page interaction is required
- **AND** no administrative capability is inferred for the resident

### Requirement: Only an active unit relationship grants resident scope

The system SHALL allow a resident to register a visit only for a unit where the authenticated user's organizational `Person` has an active and currently valid `UnitOccupancy` or `UnitOwnership`.

#### Scenario: Active occupant creates for own unit

- **GIVEN** the authenticated user's `Person` has a currently active `UnitOccupancy` on unit U
- **WHEN** the user registers a visit for U
- **THEN** the unit relationship satisfies the resident-scope precondition

#### Scenario: Active owner creates for owned unit

- **GIVEN** the authenticated user's `Person` has a currently active `UnitOwnership` on unit U
- **WHEN** the user registers a visit for U
- **THEN** the unit relationship satisfies the resident-scope precondition

#### Scenario: User without unit relationship cannot create

- **GIVEN** the authenticated user's `Person` has no active `UnitOccupancy` or `UnitOwnership` on unit U
- **WHEN** the user attempts to register a visit for U
- **THEN** authorization is denied
- **AND** no visitor or visit data is persisted

#### Scenario: Inactive resident cannot create

- **GIVEN** the user's only occupancy or ownership on unit U is inactive, expired, future-dated, or deleted
- **WHEN** the user attempts to register a visit for U
- **THEN** authorization is denied
- **AND** no visit is persisted

### Requirement: Authorized resident capability is required for immediate authorization

The system SHALL create a visit as `authorized` through this flow only when the authenticated user has both `create_visits` and `authorize_visits` for the submitted unit.

#### Scenario: Occupant with visit authorization creates authorized visit

- **GIVEN** the user's `Person` has an active and currently valid `UnitOccupancy` on unit U
- **AND** that occupancy has `can_authorize_visits = true`
- **WHEN** the user registers a valid visit for U
- **THEN** the visit is created with status `authorized`

#### Scenario: Occupant without visit authorization cannot create authorized visit

- **GIVEN** the user's `Person` has an active `UnitOccupancy` on unit U
- **AND** that occupancy has `can_authorize_visits = false`
- **WHEN** the user attempts to register an authorized visit for U
- **THEN** the request is denied
- **AND** the system does not silently elevate the user or create an `authorized` visit

#### Scenario: Ownership follows the effective domain authorization rule

- **GIVEN** the user's `Person` has an active `UnitOwnership` on unit U
- **WHEN** the user registers a visit for U
- **THEN** immediate authorization succeeds only if the current domain capability resolver grants `authorize_visits` for U
- **AND** the private API does not invent a broader ownership permission

### Requirement: Visitor is created or reused as canonical Person

The system SHALL resolve the visitor as a canonical `Person` within the current organization, reusing an existing active person by the established identity resolution rules or creating a new person when no match exists.

#### Scenario: Existing visitor Person is reused

- **GIVEN** organization O already has an active `Person` matching the submitted visitor document
- **WHEN** an authorized resident registers the visit
- **THEN** `visitor_person_id` references the existing `Person`
- **AND** no duplicate visitor identity is created

#### Scenario: New visitor Person is created

- **GIVEN** no active `Person` in organization O matches the submitted visitor identity
- **WHEN** an authorized resident registers the visit
- **THEN** the system creates a `Person` in O using the valid visitor name, document, and phone
- **AND** `visitor_person_id` references that `Person`

#### Scenario: Visitor identity is not reused across organizations

- **GIVEN** a matching document exists only as a `Person` in organization Q
- **WHEN** a resident in organization O registers the visitor
- **THEN** the system does not reuse the `Person` from Q
- **AND** identity resolution remains scoped to O

#### Scenario: Visitor profile is not the primary identity

- **WHEN** a visitor is resolved or created by this flow
- **THEN** the visit references a `Person`
- **AND** the system does not require a `visitor_profiles` record as the primary visitor identity

### Requirement: Resident and visitor references preserve Person and User semantics

The system SHALL use `Person` references for visitor identity and `User` references for authenticated action actors. This flow SHALL NOT persist a host person.

#### Scenario: Resident visit records identity and actors

- **GIVEN** authenticated user R is authorized to register a visit for unit U
- **WHEN** the visit is created successfully
- **THEN** `visitor_person_id` references the resolved visitor `Person`
- **AND** `created_by_id` references user R
- **AND** `authorized_by_id` references user R
- **AND** neither actor column references a `Person`

### Requirement: Visit location is derived from the resident unit

The system SHALL derive visit organization, residential property, and optional property section from the authenticated context and submitted `unit_id`. Client-supplied organization, property, section, actor, or status values SHALL NOT override backend resolution.

#### Scenario: Location is derived consistently

- **GIVEN** unit U belongs to property P and optional section S in organization O
- **WHEN** an authorized resident creates a visit for U
- **THEN** the visit stores O, P, S, and U consistently
- **AND** `residential_property_id` and `property_section_id` are derived from U

#### Scenario: Client cannot force another property

- **GIVEN** the resident is authorized for unit U in property P
- **WHEN** the request includes or attempts to imply property Q
- **THEN** the system ignores or rejects the untrusted property value
- **AND** no visit is created in Q

### Requirement: Cross-organization and cross-property creation are denied

The system MUST enforce organization, property, and unit isolation before resolving or persisting visit data.

#### Scenario: User from another organization cannot create

- **GIVEN** a user is authenticated in organization O
- **AND** unit U belongs to organization Q
- **WHEN** the user attempts to register a visit for U
- **THEN** the request is denied without confirming inaccessible resource details
- **AND** no record is persisted in either organization

#### Scenario: Relationship in another property does not grant access

- **GIVEN** the resident has an active relationship with unit U in property P
- **AND** unit V belongs to property Q
- **WHEN** the resident attempts to register a visit for V
- **THEN** authorization is denied
- **AND** capabilities for U or P are not reused for V or Q

#### Scenario: Relationship with another unit in the same property does not grant access

- **GIVEN** the resident has an active relationship with unit U
- **AND** has no active relationship with unit V in the same property
- **WHEN** the resident attempts to register a visit for V
- **THEN** authorization is denied
- **AND** property membership alone does not grant unit scope

### Requirement: Authorized resident creation is atomic and auditable

The system SHALL atomically resolve or create the visitor, create the authorized visit, and record the functional creation history according to the existing visit-management contract.

#### Scenario: Successful authorized creation records one coherent result

- **GIVEN** all identity, unit, authorization, and schedule validations pass
- **WHEN** the resident registration transaction commits
- **THEN** the visit is `authorized`
- **AND** `created_by_id` and `authorized_by_id` reference the authenticated `User`
- **AND** authorization time and functional history are recorded

#### Scenario: Failure rolls back the complete operation

- **GIVEN** visitor creation would be required
- **AND** visit authorization or persistence fails
- **WHEN** the transaction is rolled back
- **THEN** no partial visitor, visit, or functional history record remains from the request

### Requirement: Assigned concierge sees the resident-created authorized visit

The system SHALL expose a resident-created authorized visit through the existing concierge operational scope only to users with an active `StaffAssignment` and `view_authorized_visits` for the visit's property.

#### Scenario: Concierge for the property sees the authorized visit

- **GIVEN** a resident creates an `authorized` visit for unit U in property P
- **AND** concierge user C has an active and currently valid `StaffAssignment` for P
- **AND** C has `view_authorized_visits` for P
- **WHEN** C requests the operational authorized-visits list
- **THEN** the resident-created visit is included according to the existing operational status and time filters

#### Scenario: Concierge for another property does not see the visit

- **GIVEN** a resident creates an `authorized` visit in property P
- **AND** concierge user C is assigned only to property Q
- **WHEN** C requests the operational list
- **THEN** the visit from P is excluded

#### Scenario: Inactive concierge assignment does not grant visibility

- **GIVEN** a concierge's assignment for property P is inactive, expired, or not yet valid
- **WHEN** the concierge requests authorized visits for P
- **THEN** the resident-created visit is excluded

#### Scenario: Missing view capability denies visibility

- **GIVEN** a user has a property relationship but lacks `view_authorized_visits` for P
- **WHEN** the user requests the operational authorized-visits list
- **THEN** the resident-created visit is not returned

### Requirement: Property operational roles remain property-scoped

The system MUST continue deriving `property_admin` and `concierge` from active property-scoped `StaffAssignment` records and MUST NOT convert either role into a global role.

#### Scenario: Resident flow does not broaden operational roles

- **WHEN** the private resident visit flow is introduced
- **THEN** `property_admin` and `concierge` capabilities remain scoped to their assigned properties
- **AND** no organization-wide operational role is created as a side effect

### Requirement: Visitor person is resolved by email within the organization

The system SHALL resolve the visitor `Person` inside the current organization by document when provided, otherwise by normalized email (lower-cased, trimmed), and SHALL create a new `Person` when no match exists. The system MUST NOT merge existing persons.

#### Scenario: Existing person by email is reused

- **GIVEN** a `Person` in O with email `ana@example.com`
- **WHEN** a resident invites `Ana@Example.com`
- **THEN** the visit points to that existing `Person` and no new `Person` is created

#### Scenario: New person is created

- **GIVEN** no `Person` in O with the submitted email or document
- **WHEN** the resident submits the invitation
- **THEN** the system creates a `Person` in O with the display name, email, phone and document provided

#### Scenario: Same email in another organization is not reused

- **GIVEN** a `Person` with the same email exists only in organization P
- **WHEN** a resident of O invites that email
- **THEN** the system creates a separate `Person` in O

#### Scenario: Conflicting identity is rejected

- **GIVEN** a `Person` in O with document D and email `x@example.com`
- **WHEN** a resident submits document D with email `y@example.com`
- **THEN** the system returns `422` with a localized conflict error and persists nothing

### Requirement: Visitor is notified after the visit is created

After a resident visit is persisted, the system SHALL notify the visitor outside the creation transaction: by push and email when the visitor `Person` has a linked account, by linking and then notifying when a confirmed account with that email exists, or by issuing an onboarding invitation email when no account exists. Notification failures MUST NOT fail visit creation.

#### Scenario: Visitor with linked account gets push and email

- **GIVEN** the visitor `Person` is linked to a `User` with a registered device token
- **WHEN** the visit is created
- **THEN** a `Notification` of type `visit_invitation` and channel `push` is enqueued for that person
- **AND** an invitation email with the visit details is enqueued

#### Scenario: Existing confirmed account is linked

- **GIVEN** the visitor `Person` has no `user_id` and a confirmed `User` exists with the same email
- **WHEN** the visit is created
- **THEN** the `User` is linked to the `Person`, a `visitor` membership in O is created if the user had none
- **AND** the visitor is notified as in the linked-account scenario

#### Scenario: Visitor without account receives account invitation

- **GIVEN** no `User` exists with the visitor email
- **WHEN** the visit is created
- **THEN** an `OnboardingRequest` with relationship `visitor` is issued for the `Person`
- **AND** an email with the visit details and a single-use acceptance link is enqueued

#### Scenario: Pending invitation is not duplicated

- **GIVEN** the visitor `Person` already has a pending `OnboardingRequest`
- **WHEN** another visit is created for the same visitor
- **THEN** no new token is issued
- **AND** an email with the visit details, without acceptance link, is enqueued

#### Scenario: Notification error does not block creation

- **WHEN** issuing the invitation raises an unexpected error
- **THEN** the visit remains created with status `authorized`
- **AND** the error is recorded on the visit metadata

### Requirement: Resident resends the visitor invitation

The system SHALL let a resident with `authorize_visits` on the visit's unit resend the visitor invitation through `Visits::ResendVisitorInvitation`. The service SHALL deliver through `Visits::NotifyVisitor` (same branches as on creation), SHALL require the visit to be `authorized` and not expired, and SHALL enforce a 5-minute cooldown per visit tracked in `visit.metadata["visitor_invitation_resent_at"]`.

#### Scenario: Resend records history

- **WHEN** the invitation is resent
- **THEN** an `invitation_resent` event is added to the visit history with the resident as actor and the visit `status` unchanged

#### Scenario: Metadata is merged

- **GIVEN** a visit whose `metadata` already holds other keys
- **WHEN** the invitation is resent
- **THEN** `visitor_invitation_resent_at` is set and the other keys are preserved

#### Scenario: Delivery failure still starts the cooldown

- **GIVEN** `Visits::NotifyVisitor` fails internally and records its error
- **WHEN** the invitation is resent
- **THEN** the call succeeds, the timestamp is stored and a new attempt within 5 minutes is rejected

#### Scenario: Resend does not touch resident notifications

- **WHEN** the invitation is resent
- **THEN** no `visit_request` notification is created or retried and `notification_status` is unchanged

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
