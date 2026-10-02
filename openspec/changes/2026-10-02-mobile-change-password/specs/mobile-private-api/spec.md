# mobile-private-api

## ADDED Requirements

### Requirement: Authenticated password change
`PATCH /api/v1/private/me/password` with `current_password` and `password` SHALL change the authenticated user's password when the current password is correct and the new one satisfies the password policy, answering `204`. The token used for the request SHALL remain valid.

#### Scenario: Password changed
- **WHEN** the current password is correct and the new password is valid
- **THEN** the response is `204`, the new password logs in and the old one does not

#### Scenario: Wrong current password
- **WHEN** the current password is missing or incorrect
- **THEN** the response is `422` with `field: "current_password"` and the password is unchanged

#### Scenario: New password rejected
- **WHEN** the new password fails the policy or equals the current one
- **THEN** the response is `422` with `field: "password"` and a message naming the cause

#### Scenario: Too many attempts
- **WHEN** a user exceeds 5 attempts in 15 minutes
- **THEN** the response is `429` with a `Retry-After` header

#### Scenario: Unauthenticated
- **WHEN** the request carries no valid token
- **THEN** the response is `401`
