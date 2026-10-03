# FCM Push Notifications

## ADDED Requirements

### Requirement: Entry denied push payload
A `visit_entry_denied` push SHALL be localized in the recipient's language, SHALL name the visitor, and its `data` SHALL include `type`, `visit_id`, `unit_id` and `residential_property_id`. It MUST NOT alter the visit's aggregate `notification_status`.

#### Scenario: Payload built
- **WHEN** the payload for a `visit_entry_denied` notification is built
- **THEN** the body names the visitor and `data` carries the type and the visit, unit and property ids
