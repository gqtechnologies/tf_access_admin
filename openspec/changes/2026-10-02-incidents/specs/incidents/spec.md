# incidents

## Purpose

Records the incidents residents and front-desk staff report on a property and lets the administration follow them up to a written resolution that the reporter receives.

## ADDED Requirements

### Requirement: Residents and front-desk staff report incidents
A person holding a currently valid occupancy or ownership in a property SHALL be able to report an incident on it with a category, a description of up to 2000 characters, an optional priority, and optionally one of their own units or a common area of that property. An actor holding `report_incidents` or `manage_incidents` on the property SHALL be able to report on it too. A new incident SHALL be `open`, attributed to the reporter, with a status history entry.

#### Scenario: Resident report
- **WHEN** a resident reports a maintenance issue naming their unit and a common area
- **THEN** the incident is stored as open for that property

#### Scenario: Unit that is not theirs
- **WHEN** a resident names a unit where they have no relationship
- **THEN** the report is rejected with `403`

#### Scenario: Front desk
- **WHEN** a concierge reports on the property they operate
- **THEN** the incident is stored

#### Scenario: Outsider
- **WHEN** a member without units or staff role in the property reports
- **THEN** the report is rejected with `403`

### Requirement: Reporters follow their incidents
`GET /api/v1/private/incidents` SHALL return the incidents reported by the requesting person, newest first, with status, resolution, property, unit and common area, plus the list of categories.

#### Scenario: Only their own
- **WHEN** another resident of the same unit lists incidents
- **THEN** incidents they did not report are not returned

### Requirement: The administration manages and closes incidents
An actor holding `manage_incidents` on the property SHALL be able to change an incident's status, priority, assignee and resolution. Closing it (`resolved` or `dismissed`) SHALL require a resolution and stamp the resolution time. Every status change SHALL record a history entry and send an `incident` push to the reporter, naming the category and, when closed, the resolution. Concierges and residents SHALL NOT manage incidents.

#### Scenario: Closing without a resolution
- **WHEN** an administrator marks an incident resolved without a resolution
- **THEN** the change is refused

#### Scenario: Resolved
- **WHEN** an administrator resolves it with a resolution
- **THEN** the reporter receives a push with that resolution

#### Scenario: Priority only
- **WHEN** only the priority changes
- **THEN** no notification is sent
