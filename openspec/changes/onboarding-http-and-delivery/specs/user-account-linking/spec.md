# User Account Linking

## ADDED Requirements

### Requirement: Confirmation gate is enforced at the session layer

The system SHALL block an unconfirmed `User` from using the application at authentication time (no unconfirmed grace period), even when the account is linked or incorporated.

#### Scenario: Unconfirmed account cannot authenticate into the app

- **GIVEN** a linked but unconfirmed `User`
- **WHEN** the user attempts to authenticate
- **THEN** the system denies access until confirmation
