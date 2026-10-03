# mobile-client-auth

## Purpose


Authenticates the mobile app against the API: password login, Apple and Google sign-in, password recovery, and the authenticated profile endpoints, always scoped to the requesting organization.

## Requirements

### Requirement: Tenant-less login for the global client role
The system SHALL provide `POST /api/v1/mobile/auth/login`, which authenticates a user by email and password without resolving, requiring, or exposing any `Organization`/tenant context. The endpoint SHALL be reachable regardless of request subdomain (including no subdomain) and SHALL NOT set `Current.organization` or activate `ActsAsTenant.current_tenant`.

#### Scenario: Successful login without a tenant subdomain
- **WHEN** a user with valid credentials and the global `client` role submits `POST /api/v1/mobile/auth/login` with `email` and `password`, from a request with no organization subdomain
- **THEN** the system responds `200 OK` with `data.token`, `data.token_type`, `data.expires_in`, and `data.user` containing `id`, `email`, and `name`
- **AND** the response does not include a `role` field
- **AND** the `Authorization` response header carries the same JWT as `data.token`

#### Scenario: Invalid credentials
- **WHEN** a login is submitted with an email that does not exist, or a password that does not match
- **THEN** the system responds `401 Unauthorized` with the same invalid-credentials error used by the tenant login endpoint

#### Scenario: Account not confirmed
- **WHEN** a user with valid credentials has not confirmed their account
- **THEN** the system responds `401 Unauthorized` with the same unconfirmed-account error used by the tenant login endpoint

#### Scenario: Account deactivated
- **WHEN** a user with valid credentials has `deactivated_at` present
- **THEN** the system responds `401 Unauthorized` with an account-deactivated error, and no JWT is issued

#### Scenario: User lacks the global client role
- **WHEN** a user with valid, confirmed, active credentials does not hold the global `client` role in any organization
- **THEN** the system responds `403 Forbidden`, and no JWT is issued

### Requirement: Account deactivation gate applies to tenant login as well
The system SHALL reject authentication at `POST /api/v1/auth/login` (existing tenant login) for a user whose `deactivated_at` is present, using the same rejection semantics as the mobile login endpoint.

#### Scenario: Deactivated account rejected on tenant login
- **WHEN** a user with valid credentials, a confirmed account, and `deactivated_at` present submits `POST /api/v1/auth/login` with a resolvable organization subdomain
- **THEN** the system responds `401 Unauthorized` with an account-deactivated error, and no JWT is issued

### Requirement: Mobile endpoints require authentication by default
The system SHALL require a valid authenticated user (via the mobile-issued JWT) for every `api/v1/mobile/*` endpoint, except `POST /api/v1/mobile/auth/login`, which SHALL remain reachable without authentication.

#### Scenario: Unauthenticated request to a protected mobile endpoint
- **WHEN** a request to a protected `api/v1/mobile/*` endpoint (e.g. `GET /api/v1/mobile/me`) is made with no `Authorization` header, or an invalid/expired JWT
- **THEN** the system responds `401 Unauthorized`

#### Scenario: Login remains reachable without authentication
- **WHEN** `POST /api/v1/mobile/auth/login` is called with no `Authorization` header
- **THEN** the request is processed normally (not rejected for lack of authentication)

### Requirement: Authenticated user profile endpoint
The system SHALL provide `GET /api/v1/mobile/me`, which returns the authenticated user's `email`, `name`, and `dni`. The endpoint SHALL NOT resolve or expose any organization, role, or unit data.

#### Scenario: Authenticated user fetches their profile
- **WHEN** an authenticated user (valid JWT) calls `GET /api/v1/mobile/me`
- **THEN** the system responds `200 OK` with `data.email`, `data.name`, and `data.dni` matching the authenticated user's record

### Requirement: Authenticated user profile update endpoint
The system SHALL provide `PATCH /api/v1/mobile/me`, accepting `name`, `phone` (`{countryCode, number}` or `null`), `dateOfBirth`, `gender`, and optional multipart `avatar`, updating the authenticated user, and responding with the same shape as `GET /me`.

#### Scenario: Authenticated user updates their profile
- **WHEN** an authenticated user calls `PATCH /api/v1/mobile/me` with valid `name`, `phone`, `dateOfBirth`, and `gender`
- **THEN** the system responds `200 OK` with the updated `data.name`, `data.phone`, `data.dateOfBirth`, `data.gender`

#### Scenario: Explicit null phone clears stored phone
- **GIVEN** the user has a stored phone number
- **WHEN** `PATCH /api/v1/mobile/me` is called with `phone: null`
- **THEN** the response's `data.phone` is `null`

#### Scenario: Invalid gender is rejected
- **WHEN** `PATCH /api/v1/mobile/me` is called with a `gender` value outside `female`/`male`/`other`/`prefer_not_to_say`
- **THEN** the system responds `422 Unprocessable Entity`
- **AND** the user's stored gender is unchanged

#### Scenario: Avatar upload persists
- **WHEN** `PATCH /api/v1/mobile/me` is called as `multipart/form-data` with an `avatar` file
- **THEN** the file is attached to the user's `avatar`

### Requirement: Profile response includes phone, date of birth, and gender
The system SHALL include `phone`, `dateOfBirth`, and `gender` in `GET /api/v1/mobile/me`'s response, each `null` when not set.

#### Scenario: Unset fields render as null
- **GIVEN** a user with no stored phone, date of birth, or gender
- **WHEN** `GET /api/v1/mobile/me` is called
- **THEN** `data.phone`, `data.dateOfBirth`, and `data.gender` are all `null`

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
