# Residential Visit Management

## ADDED Requirements

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
