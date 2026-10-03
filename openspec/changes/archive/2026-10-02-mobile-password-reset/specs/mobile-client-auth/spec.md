# mobile-client-auth

## ADDED Requirements

### Requirement: Password reset request from the API
`POST /api/v1/auth/password` with an `email` SHALL resolve the organization from the request subdomain or the `X-Tenant-Subdomain` header and, when the email belongs to a confirmed, non-deactivated member of that organization, send the password reset instructions to that email. The response SHALL be `202` with the same body whether or not an email was sent, so the endpoint does not reveal which emails are registered. The request SHALL NOT require authentication.

#### Scenario: Registered member
- **WHEN** the email belongs to a confirmed, active member of the organization
- **THEN** the response is `202` and the reset instructions are emailed

#### Scenario: Unknown email or another organization's user
- **WHEN** the email is not a member of the resolved organization
- **THEN** the response is `202` and no email is sent

#### Scenario: Deactivated or unconfirmed account
- **WHEN** the member is deactivated or has not confirmed the account
- **THEN** the response is `202` and no email is sent

#### Scenario: Missing email
- **WHEN** the `email` parameter is blank
- **THEN** the response is `422`

#### Scenario: Unknown organization
- **WHEN** no organization matches the subdomain
- **THEN** the response is `401` like the login endpoint

#### Scenario: Too many requests
- **WHEN** an IP exceeds 5 requests in 15 minutes
- **THEN** the response is `429` with a `Retry-After` header

### Requirement: Reset link points at the member's organization
The reset instructions email SHALL link to the password edit page on the subdomain of the organization the reset was requested from.

#### Scenario: Link host
- **WHEN** the reset is requested for organization `edificiod`
- **THEN** the email link host starts with `edificiod.`
