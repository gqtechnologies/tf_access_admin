# common-area-reservations

## Purpose

Lets a property's administration offer common areas with their booking rules, lets permitted residents book them from the app, and records the approval cycle of each booking.

## ADDED Requirements

### Requirement: Administrators configure common areas and their rules
An actor holding `manage_common_areas` on a property SHALL be able to create and edit its common areas (name, type, optional capacity, whether bookings require approval, available or closed) and set or clear these rules: opening time, closing time (both `HH:MM`, opening before closing), maximum duration in minutes, minimum notice in hours, maximum bookings per unit per month, and instructions. Invalid rules SHALL be rejected without saving.

#### Scenario: Area with rules
- **WHEN** an administrator creates an area with opening hours and a maximum duration
- **THEN** the area is stored with those rules

#### Scenario: Clearing a rule
- **WHEN** a rule is saved blank
- **THEN** it is removed and no longer enforced

#### Scenario: Reversed hours
- **WHEN** the opening time is not before the closing time
- **THEN** nothing is saved and an error is shown

### Requirement: Permitted residents book common areas
A person holding a currently valid occupancy of a unit with `can_reserve_common_areas` SHALL be able to book an available area of that unit's property for a time range, with a guest count. The booking SHALL be approved immediately when the area does not require approval and pending otherwise, and a status history entry SHALL be recorded. Owners without an occupancy, occupants without the permission and areas of another property SHALL be rejected.

#### Scenario: Area requiring approval
- **WHEN** a permitted resident books an area that requires approval
- **THEN** the booking is pending

#### Scenario: Area without approval
- **WHEN** a permitted resident books an area that does not require approval
- **THEN** the booking is approved at once

#### Scenario: No permission
- **WHEN** an occupant without the permission tries to book
- **THEN** the booking is rejected with `403`

### Requirement: Bookings respect the rules and never overlap
A booking SHALL be rejected when the area is closed, the range is empty or in the past, the guest count exceeds the capacity, it starts before the minimum notice, it lasts longer than the maximum, it falls outside the opening hours of its start day in the property's time zone, or the unit already holds the monthly maximum of active bookings for that area in that month. A booking SHALL be rejected when it overlaps another pending or approved booking of the same area; back-to-back bookings SHALL be allowed and rejected or cancelled bookings SHALL free their slot.

#### Scenario: Rule violation
- **WHEN** a booking breaks a rule
- **THEN** the API responds `422` with a `code` naming the rule and a localized message

#### Scenario: Overlap
- **WHEN** the range overlaps an active booking of the same area
- **THEN** the API responds `409` with `code: "slot_taken"`

### Requirement: Administrators decide and residents are told
An actor holding `manage_common_areas` SHALL be able to approve or reject (with an optional reason) a pending booking and cancel an upcoming approved one. Each decision SHALL record a history entry and send a `reservation` push to the resident who booked, naming the area, the date and, for a rejection, the reason. The resident who booked SHALL be able to cancel their own pending or approved booking before it starts, without a push.

#### Scenario: Approval
- **WHEN** an administrator approves a pending booking
- **THEN** it becomes approved with who approved it and the resident gets a push

#### Scenario: Not pending
- **WHEN** an administrator tries to approve or reject a booking that is no longer pending
- **THEN** it is rejected and nothing changes

#### Scenario: Someone else cancels
- **WHEN** another resident of the unit tries to cancel the booking
- **THEN** the API responds `403`

### Requirement: Residents see areas, availability and the unit's bookings
The API SHALL list the available areas of a unit's property with their rules and whether the requester may book, the slots taken on a given day of an area, and the unit's bookings of the last 30 days onward with whether the requester may cancel each.

#### Scenario: Availability
- **WHEN** a resident asks for an area's availability on a day with one pending booking
- **THEN** that booking's range is returned
