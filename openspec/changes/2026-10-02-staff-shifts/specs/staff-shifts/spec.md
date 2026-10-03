# staff-shifts

## Purpose

Records the front-desk shifts of each property — who was on duty, when, what they handed over — and ties the parcels received to the shift.

## ADDED Requirements

### Requirement: Workers open and close their shift
A person with a current staff assignment on a property SHALL be able to open a shift there, with at most one open shift per person, and close their own open shift with an optional handover note. Opening without an assignment SHALL be refused with `403`; opening a second shift or closing without one SHALL be refused with `422`.

#### Scenario: Shift cycle
- **WHEN** a concierge opens a shift and later closes it with a note
- **THEN** the shift records the start, the end and the note

#### Scenario: Not assigned
- **WHEN** a resident or a concierge of another property tries to open a shift
- **THEN** the request is refused

### Requirement: The next worker reads the handover
`GET /api/v1/private/concierge/shift?property_id=` SHALL return the requester's open shift on the property (start and parcels received so far), or none, and the last closed shift of the property with who closed it, when and its note.

#### Scenario: Handover
- **WHEN** the previous shift closed with a note
- **THEN** the next worker sees that note and who wrote it

### Requirement: Parcels are tied to the shift
A parcel received by a worker who has an open shift on the parcel's property SHALL be linked to that shift.

#### Scenario: Received during a shift
- **WHEN** a concierge with an open shift registers a parcel
- **THEN** the parcel belongs to that shift and the shift's count goes up

### Requirement: The administration reviews the shift log
An actor holding `manage_staff_assignments` SHALL see, per property and day in the property's time zone, the shifts that overlapped that day with worker, start, end, duration, parcels received and handover note.

#### Scenario: Day log
- **WHEN** an administrator opens the log for a day with one closed shift
- **THEN** it shows that shift with its note and parcel count
