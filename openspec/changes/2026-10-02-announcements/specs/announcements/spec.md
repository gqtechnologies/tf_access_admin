# announcements

## Purpose

Lets a property's administration write announcements and deliver them to every current resident of that property, by push and in the app, and see who read or acknowledged them.

## ADDED Requirements

### Requirement: Administrators draft and publish announcements
An actor holding `manage_announcements` on a property SHALL be able to create announcements for it as drafts (title up to 150 characters, message up to 5000, category, priority, optional expiry later than the publication, optional acknowledgement requirement), edit them while they are drafts, publish them and archive published ones. Organization administrators SHALL hold the capability on every property and property administrators on their managed properties.

#### Scenario: Draft created
- **WHEN** an administrator saves a new announcement for a property
- **THEN** it is stored as a draft authored by that administrator and nobody is notified

#### Scenario: Published announcement is not editable
- **WHEN** an administrator tries to edit a published announcement
- **THEN** the change is rejected

#### Scenario: Property administrator of another property
- **WHEN** a property administrator acts on an announcement of a property they do not manage
- **THEN** the action is not authorized

#### Scenario: Concierge or resident
- **WHEN** a concierge or a resident tries to publish
- **THEN** the action is not authorized

### Requirement: Publishing notifies every resident of the property
Publishing SHALL set the status to `published` with the publication time and create one `announcement` push notification for each person holding a currently valid occupancy or ownership of any unit of the property. A failure to notify SHALL NOT undo the publication.

#### Scenario: Several units
- **WHEN** an announcement is published for a property with residents in two units and an owner who also lives there
- **THEN** each distinct person receives exactly one notification and residents of other properties receive none

#### Scenario: Already published
- **WHEN** a published announcement is published again
- **THEN** it is rejected and no notification is created

### Requirement: Residents read and acknowledge announcements
`GET /api/v1/private/announcements` SHALL return, newest first, the published and unexpired announcements of the properties where the requesting person holds a currently valid occupancy or ownership, each with `read` and `acknowledged` flags, plus `unread_count`. Opening one with `GET /announcements/:id` SHALL record the read. `POST /announcements/:id/acknowledge` SHALL record the acknowledgement for announcements that require it and answer `422` otherwise.

#### Scenario: Listing
- **WHEN** a resident requests the announcements
- **THEN** drafts, archived, expired and other properties' announcements are left out

#### Scenario: Opening and acknowledging
- **WHEN** the resident opens an announcement and then acknowledges it
- **THEN** it is marked read and acknowledged and no longer counts as unread

#### Scenario: Announcement not visible to the person
- **WHEN** the id belongs to another property or to a non-visible announcement
- **THEN** the response is `404`

### Requirement: Administrators see reach and reads
The administration page SHALL show, per property, the announcements by status with counters, how many people the property's announcements reach, and for published ones how many residents read and acknowledged them.

#### Scenario: Read statistics
- **WHEN** one resident has read and acknowledged a published announcement
- **THEN** the page shows one read and one acknowledgement for it
