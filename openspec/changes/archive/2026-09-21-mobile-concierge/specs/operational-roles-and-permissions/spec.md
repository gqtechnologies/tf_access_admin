# Operational Roles and Permissions

## ADDED Requirements

### Requirement: API role for concierge staff

The role exposed by the mobile API (login and profile) SHALL be `concierge` when the user holds an active `concierge` staff assignment in the organization and holds none of `super_admin`, `tenant_admin`, `manager` or `content_manager`. The `visitor` organizational role MUST NOT take precedence over an active concierge assignment.

#### Scenario: Concierge logs in

- **GIVEN** a confirmed member with an active concierge assignment on property P
- **WHEN** they log in through the API
- **THEN** the returned role is `concierge`

#### Scenario: Administrative role wins

- **GIVEN** a `tenant_admin` who also holds a concierge assignment
- **WHEN** their API role is resolved
- **THEN** it is `tenant_admin`

#### Scenario: Concierge previously invited as visitor

- **GIVEN** a user with the `visitor` organizational role and an active concierge assignment
- **WHEN** their API role is resolved
- **THEN** it is `concierge`

#### Scenario: Inactive assignment

- **GIVEN** a user whose only concierge assignment is inactive or ended
- **WHEN** their API role is resolved
- **THEN** it is `resident`
