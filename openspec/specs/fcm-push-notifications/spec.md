# fcm-push-notifications Specification

## Purpose

Deliver push notifications to residents' mobile devices via Firebase Cloud Messaging (FCM), covering device token lifecycle, asynchronous non-blocking delivery, environment-configurable transport, and auditable delivery history.

## Requirements

### Requirement: Device token registration
The system SHALL allow an authenticated `User` to register their device's FCM token through a private, tenant-scoped API endpoint. A `User` SHALL have at most one registered device token at a time: registering a new token replaces any previously registered token for that user.

#### Scenario: Authenticated user registers a device token
- **GIVEN** a `User` is authenticated in organization O and has no registered device token
- **WHEN** the user submits a device token and platform (`ios`, `android`, or `web`) to the registration endpoint
- **THEN** the system creates a `device_tokens` record owned by that user
- **AND** subsequent notifications for that user's `Person` may be delivered to this token

#### Scenario: Registering a new device token replaces the previous one
- **GIVEN** a `User` already has a registered device token from device A
- **WHEN** the same user authenticates on device B and registers device B's token
- **THEN** the system replaces the stored token with device B's token
- **AND** device A no longer receives push notifications for this user

#### Scenario: Unauthenticated registration is rejected
- **GIVEN** no authenticated user
- **WHEN** a device token registration request is made
- **THEN** the system denies the request

### Requirement: Device token revocation
The system SHALL allow an authenticated `User` to revoke their own registered device token.

#### Scenario: User revokes their own device token
- **GIVEN** a `User` has a registered device token
- **WHEN** the user requests revocation
- **THEN** the system deletes the `device_tokens` record
- **AND** no further notifications are delivered to that user's device

### Requirement: Environment-configurable FCM transport
The system SHALL send push notifications via HTTP POST to a configurable FCM-compatible base URL, defaulting to the real Firebase endpoint, so that development environments can redirect delivery to a local simulator without code changes.

#### Scenario: Default configuration targets real Firebase
- **GIVEN** `FCM_BASE_URL` is not set
- **WHEN** the system sends a push notification
- **THEN** the request is sent to `https://fcm.googleapis.com`

#### Scenario: Development configuration targets the local simulator
- **GIVEN** `FCM_BASE_URL` is set to `http://localhost:8090`
- **WHEN** the system sends a push notification
- **THEN** the request is sent to the configured local address instead of the default

### Requirement: Push notification delivery is asynchronous and non-blocking
The system SHALL deliver push notifications through a background job. A delivery failure MUST NOT affect the operation that triggered the notification.

#### Scenario: Delivery happens after the triggering action completes
- **GIVEN** an action that triggers a notification (e.g. visit creation) has completed
- **WHEN** the system creates a `Notification` record for a recipient
- **THEN** delivery to that recipient's device tokens is enqueued as a background job
- **AND** the triggering action's result does not wait for delivery to finish

#### Scenario: FCM delivery failure does not roll back the triggering action
- **GIVEN** a `Notification` has been created and delivery is enqueued
- **WHEN** the FCM request fails (e.g. connection error, non-2xx response)
- **THEN** the triggering action's data (e.g. the created visit) remains committed
- **AND** the `Notification`'s status, attempts count, and last error are updated to reflect the failure

#### Scenario: Recipient with no registered device token is not treated as an error
- **GIVEN** a `Notification` recipient's `Person` has no associated `User`, or that `User` has no registered device token
- **WHEN** the delivery job processes that notification
- **THEN** the `Notification` is marked as skipped (a terminal, non-pending outcome) rather than left pending indefinitely
- **AND** no error is recorded

### Requirement: Delivery is attempted exactly once per enqueue; only a manual resend retries it
The system SHALL NOT automatically retry a failed push delivery in the background. A single delivery attempt SHALL always reach a terminal outcome (recorded on the `Notification`) rather than being silently retried by the job queue.

#### Scenario: A failed delivery does not retry itself
- **GIVEN** a push delivery attempt fails (e.g. connection error, non-2xx FCM response)
- **WHEN** the delivery job finishes processing that attempt
- **THEN** the system does not automatically schedule another attempt for the same notification
- **AND** the `Notification`'s failure is immediately reflected in its status

#### Scenario: Every delivery attempt updates the notification, success or failure
- **GIVEN** a delivery job is processing a `Notification`
- **WHEN** the underlying FCM request completes, whether successfully or not
- **THEN** the job records the outcome on the `Notification` without raising an unhandled error
- **AND** the notification never remains stuck reflecting a stale in-flight state after the job finishes

### Requirement: Push payload includes enough data to deep-link without a follow-up request
A visit-request push notification's data payload SHALL include the visit's id, the notification type, the residential property's name, the unit's identifier, and the visitor's name, so a mobile client can render and deep-link to the relevant visit without an additional API call.

#### Scenario: Visit request push includes deep-link data
- **GIVEN** a visit-request `Notification` is delivered
- **WHEN** the push notification is sent
- **THEN** its data payload includes `type: "visit_request"`, the visit's id, the residential property's name, the unit's identifier, and the visitor's name

### Requirement: A device receives notifications for every organization its user is a resident authorizer in
The system SHALL NOT scope device token delivery to a single organization. A `User` who is an active resident authorizer in more than one organization SHALL receive push notifications for all of them on their single registered device.

#### Scenario: A multi-organization resident receives notifications from each organization
- **GIVEN** a `User` is an active resident authorizer for units in organization O1 and organization O2
- **AND** that user has one registered device token
- **WHEN** a visit is created for a unit the user authorizes in O1, and separately for a unit in O2
- **THEN** the user's single device receives a push notification for each visit, regardless of which organization it came from

### Requirement: Notification delivery history is preserved across attempts
The system SHALL preserve an auditable history of each delivery attempt for a `Notification`, including attempts made via a manual resend, rather than only reflecting the most recent attempt's outcome.

#### Scenario: A resent notification's prior attempt remains inspectable
- **GIVEN** a `Notification` failed on its first delivery attempt
- **AND** it was later resent and reached a different outcome
- **THEN** the history of the first attempt (its status and error) remains available for inspection
- **AND** it is not indistinguishably overwritten by the later attempt

### Requirement: Expo Push transport is selected by token format

The system SHALL deliver push notifications through the Expo Push Service when the device token starts with `ExponentPushToken[`, and through FCM otherwise. The Expo base URL SHALL be configurable through `EXPO_PUSH_BASE_URL` (default `https://exp.host`) and an optional access token SHALL be read from credentials. Both transports SHALL expose the same result contract and MUST NOT raise.

#### Scenario: Expo token routes to Expo

- **GIVEN** a device token `ExponentPushToken[abc]`
- **WHEN** a push notification is delivered
- **THEN** the request is sent to `{EXPO_PUSH_BASE_URL}/--/api/v2/push/send`
- **AND** FCM is not called

#### Scenario: FCM token routes to FCM

- **GIVEN** a device token that does not start with `ExponentPushToken[`
- **WHEN** a push notification is delivered
- **THEN** the request is sent to FCM as before

#### Scenario: Transport failure is recorded, not raised

- **WHEN** the Expo service is unreachable
- **THEN** the notification is marked `failed` with the error message
- **AND** the job completes without exception

### Requirement: Unregistered device tokens are invalidated

When a transport reports that the device is no longer registered, the system SHALL mark the notification `failed` and delete the user's device token so no further attempts target it.

#### Scenario: DeviceNotRegistered removes the token

- **GIVEN** a user with device token T
- **WHEN** Expo responds with error `DeviceNotRegistered` for T
- **THEN** the notification is `failed`
- **AND** the user's device token no longer exists

### Requirement: Visit invitation push payload

The system SHALL support notification type `visit_invitation`, addressed to the visitor person, whose payload carries `data: { type: "visit_invitation", visit_id, residential_property_name, unit_identifier, scheduled_at }` and a localized title and body.

#### Scenario: Payload deep-links to the invitation

- **WHEN** a `visit_invitation` notification is delivered
- **THEN** the payload data includes the `visit_id` and `type: "visit_invitation"`
- **AND** the title and body use the recipient user's language

### Requirement: Visit request payload carries unit and property ids

The `data` of a `visit_request` push SHALL include `unit_id` and `residential_property_id` alongside the existing keys, so the mobile client can open that unit's visit management directly.

#### Scenario: Payload built

- **WHEN** the payload for a `visit_request` notification is built
- **THEN** `data` contains `visit_id`, `unit_id` and `residential_property_id` matching the visit

### Requirement: Entry denied push payload
A `visit_entry_denied` push SHALL be localized in the recipient's language, SHALL name the visitor, and its `data` SHALL include `type`, `visit_id`, `unit_id` and `residential_property_id`. It MUST NOT alter the visit's aggregate `notification_status`.

#### Scenario: Payload built
- **WHEN** the payload for a `visit_entry_denied` notification is built
- **THEN** the body names the visitor and `data` carries the type and the visit, unit and property ids
