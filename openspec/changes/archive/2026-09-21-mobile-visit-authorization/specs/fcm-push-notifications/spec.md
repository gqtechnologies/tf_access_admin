# FCM Push Notifications

## ADDED Requirements

### Requirement: Visit request payload carries unit and property ids

The `data` of a `visit_request` push SHALL include `unit_id` and `residential_property_id` alongside the existing keys, so the mobile client can open that unit's visit management directly.

#### Scenario: Payload built

- **WHEN** the payload for a `visit_request` notification is built
- **THEN** `data` contains `visit_id`, `unit_id` and `residential_property_id` matching the visit
