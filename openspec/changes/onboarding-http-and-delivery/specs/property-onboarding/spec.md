# Property Onboarding

## ADDED Requirements

### Requirement: Invitation token is delivered by email

The system SHALL deliver an onboarding invitation to the destination email as a single-use, time-limited link. The email SHALL identify the inviting organization by name, and MUST NOT contain the raw token outside the link, sensitive personal data (document), the holder's other emails, or any other organization the holder belongs to.

#### Scenario: Invitation email carries only a single-use link and the inviting org

- **WHEN** an invitation is issued
- **THEN** the system sends an email containing a single-use, expiring link
- **AND** the email names the inviting organization
- **AND** contains no document, no other-organization data, and no token beyond the link

#### Scenario: Delivery does not block issuance

- **GIVEN** an invitation is issued
- **WHEN** email delivery is enqueued
- **THEN** the onboarding request is persisted regardless of delivery timing

### Requirement: Acceptance creates a new account when none exists

When an invitation has no resolved account, the system SHALL create a new `User` at acceptance (the holder setting their password) and link it to the person explicitly, without relying on an implicit provisioning hook.

#### Scenario: New-account acceptance links and activates

- **GIVEN** a pending invitation with no resolved account
- **WHEN** the holder accepts and sets a password
- **THEN** the system creates a `User`, links it to the person, and activates the membership per the join rules

#### Scenario: Accepting by token confirms the email

- **GIVEN** a pending invitation
- **WHEN** the holder opens the single-use link and accepts
- **THEN** the system marks the account's email as confirmed
- **AND** does not require a separate confirmation email

### Requirement: Onboarding endpoints derive tenant from context

The system SHALL expose onboarding actions (invite/incorporate, revoke, resolve conflict, accept) as endpoints that derive the organization from the request context and authorize via the onboarding policy. Endpoints MUST NOT accept a tenant identifier from the client.

#### Scenario: Manager invite endpoint is authorized and tenant-safe

- **GIVEN** a manager with `manage_people`
- **WHEN** the manager posts an invitation without a tenant identifier
- **THEN** the system creates the invitation in the context organization

#### Scenario: Conflict resolution endpoint requires the dedicated capability

- **GIVEN** an actor without `resolve_identity_conflicts`
- **WHEN** the actor calls the conflict-resolution endpoint
- **THEN** the system denies the request
