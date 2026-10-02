# mobile-client-auth

## ADDED Requirements

### Requirement: Identity tokens are verified before use
`POST /api/v1/auth/social` SHALL accept an identity token only when its RS256 signature matches the provider's published keys, its issuer is the named provider, it has not expired, and its audience is one of the audiences configured for that provider. Anything else SHALL be answered `401` without issuing a session.

#### Scenario: Valid token
- **WHEN** the token is signed by the provider for this app and is not expired
- **THEN** its email, verification flag and name are used for the sign-in

#### Scenario: Token for another app, forged or expired
- **WHEN** the audience is not configured, the signature does not match, the issuer differs, the token is unsigned or it has expired
- **THEN** the response is `401` and no session is issued

#### Scenario: Provider not configured
- **WHEN** the provider has no audience configured
- **THEN** the response is `503`

#### Scenario: Email not verified
- **WHEN** the token carries no email or the provider has not verified it
- **THEN** the response is `422` and no account is created

### Requirement: Social sign-in resolves or creates the account
With a verified email the endpoint SHALL resolve the organization from the subdomain or `X-Tenant-Subdomain` and answer with the same session payload as the password login, plus `created`. An email that already belongs to a member SHALL sign in to that account with its role. An email with an account in another organization, or matching a person of this organization that has no account yet, SHALL join the organization as a visitor reusing that person. An unknown email SHALL create a confirmed visitor account.

#### Scenario: Existing member
- **WHEN** the email belongs to a member of the organization
- **THEN** the response is `200` with that user's session and role, and `created` is `false`

#### Scenario: New account
- **WHEN** the email is unknown and name and document are provided
- **THEN** a confirmed account is created as a visitor member and the response is `200` with `created: true`

#### Scenario: Profile data missing
- **WHEN** the account has to be created and the name or the document is missing
- **THEN** the response is `422` with `code: "profile_required"`, the `missing` fields and the provider's `suggested_name`, and nothing is created

#### Scenario: Person already invited
- **WHEN** a person with that email exists in the organization without an account
- **THEN** the new account is linked to that person instead of creating another

#### Scenario: Deactivated account
- **WHEN** the account is deactivated
- **THEN** the response is `401`

#### Scenario: Too many requests
- **WHEN** an IP exceeds 10 requests in 15 minutes
- **THEN** the response is `429` with a `Retry-After` header
