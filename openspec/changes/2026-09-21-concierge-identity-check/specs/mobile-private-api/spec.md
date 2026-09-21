# Mobile Private API

## ADDED Requirements

### Requirement: Concierge verifies the visitor by photo
Each concierge visit entry SHALL expose `visitor.avatar_url` with the profile photo of the visitor's linked user, or `null`. Through this API a visit whose visitor has no photo MUST NOT be checked in: `can_check_in` SHALL be `false` and `POST check_in` SHALL respond `422`. The check-in endpoint SHALL accept no operational fields.

#### Scenario: Visitor with photo
- **GIVEN** an authorized visit within its validity window whose visitor has an account with a profile photo
- **WHEN** the concierge lists visits
- **THEN** the entry has a non-null `visitor.avatar_url` and `can_check_in: true`

#### Scenario: Visitor without photo
- **GIVEN** the visitor has no account, or no profile photo
- **WHEN** the concierge lists visits and then POSTs check_in
- **THEN** the entry has `visitor.avatar_url: null` and `can_check_in: false`, and the POST responds `422` leaving the visit `authorized`

### Requirement: Concierge denies entry on identity mismatch
The system SHALL expose `POST /api/v1/private/concierge/visits/:id/deny_entry`. It SHALL keep the visit `authorized`, record an `entry_denied` history event with the concierge as actor, and notify only the visit's host (`authorized_by`, else `created_by`). It SHALL enforce a 5-minute cooldown per visit.

#### Scenario: Entry denied
- **WHEN** the concierge POSTs deny_entry on an authorized visit
- **THEN** the response is `200`, the visit is still `authorized`, the history has an `entry_denied` event, and exactly one `visit_entry_denied` push notification is created for the host

#### Scenario: Other residents are not notified
- **GIVEN** a unit with two residents where one of them invited the visitor
- **WHEN** entry is denied
- **THEN** only the inviting resident receives a notification

#### Scenario: Cooldown
- **WHEN** deny_entry is POSTed again within 5 minutes
- **THEN** the response is `429` with `Retry-After` and no new notification is created

#### Scenario: Not an authorized visit
- **WHEN** deny_entry is POSTed on a `checked_in` or `cancelled` visit
- **THEN** the response is `422` or `404` and nothing is recorded

#### Scenario: No capability
- **WHEN** a resident POSTs deny_entry
- **THEN** the response is `403` or `404`
