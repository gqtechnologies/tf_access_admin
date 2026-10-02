# mobile-private-api

## ADDED Requirements

### Requirement: Notification inbox endpoint
`GET /api/v1/private/notifications` SHALL return the push notifications addressed to the requesting person in the current organization and created in the last 60 days, newest first and paginated, regardless of whether the push was delivered. Each entry SHALL carry `id`, `type`, `title`, `body`, `data` (the same payload as the push), `read` and `created_at`. The response SHALL include `unread_count` and `pagination`. A notification whose subject can no longer be rendered SHALL be omitted.

#### Scenario: Listing
- **WHEN** a member requests the inbox
- **THEN** the response is `200` with only that person's notifications and the count of unread ones

#### Scenario: Old notifications
- **WHEN** a notification is older than 60 days
- **THEN** it is neither listed nor counted

#### Scenario: Unauthenticated
- **WHEN** the request carries no valid token
- **THEN** the response is `401`

### Requirement: Marking notifications as read
`POST /api/v1/private/notifications/:id/read` SHALL mark that notification as read, keeping the first read time, and `POST /api/v1/private/notifications/read_all` SHALL mark every unread notification of the requesting person. Both SHALL answer with the remaining `unread_count`.

#### Scenario: One notification
- **WHEN** the person marks one of their notifications
- **THEN** it becomes read and `unread_count` reflects the rest

#### Scenario: Someone else's notification
- **WHEN** the id belongs to another person
- **THEN** the response is `404` and nothing changes

#### Scenario: All at once
- **WHEN** the person marks all as read
- **THEN** their unread notifications become read and other people's are untouched
