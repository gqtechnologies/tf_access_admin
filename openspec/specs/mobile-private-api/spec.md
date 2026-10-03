# mobile-private-api Specification

## Purpose

The authenticated private API the mobile app uses: profile, units, organization detail, visits, invitations, residents, parcels, concierge operations, notifications and device tokens.

## Requirements

### Requirement: Private API login is available to any confirmed tenant member

The system SHALL authenticate a `User` through `POST /api/v1/auth/login` when the credentials are valid, the account is confirmed and the user is a member of the organization resolved from the request subdomain. The response SHALL include `role` with one of `tenant_admin`, `resident`, `visitor`.

#### Scenario: Resident logs in

- **GIVEN** a confirmed `User` whose `Person` has an active `UnitOccupancy` in organization O and no organizational role
- **WHEN** the user submits valid credentials to O's subdomain
- **THEN** the system returns `200` with a JWT and `role: "resident"`

#### Scenario: Visitor logs in

- **GIVEN** a confirmed `User` with an active `OrganizationMembership` with role `visitor` in O
- **WHEN** the user submits valid credentials to O's subdomain
- **THEN** the system returns `200` with a JWT and `role: "visitor"`

#### Scenario: Non-member is rejected

- **GIVEN** a confirmed `User` with no membership nor unit relationship in O
- **WHEN** the user submits valid credentials to O's subdomain
- **THEN** the system rejects the request with `401` (same response as invalid credentials, so accounts are not enumerable) and no token

### Requirement: Profile endpoint

The system SHALL expose `GET /api/v1/private/me` returning `{ data: { email, name, dni, phone: { countryCode, number } | null, dateOfBirth: string | null, gender: null, avatarUrl: string | null, role, organizations: [{ id, name, logo: string | null, units_count }] } }` for the authenticated user, and `PATCH /api/v1/private/me` accepting `name`, `phone`, `dateOfBirth` and a multipart `avatar`.

#### Scenario: Profile reflects the current tenant's person

- **GIVEN** an authenticated resident whose `Person` in O has a phone and birthdate
- **WHEN** the user requests `GET /me`
- **THEN** `phone` and `dateOfBirth` come from that `Person`
- **AND** `organizations` lists only organizations where the user has an active membership or unit relationship
- **AND** `gender` is `null`

#### Scenario: Profile update persists name and avatar

- **WHEN** the user sends `PATCH /me` with a new `name` and an image `avatar`
- **THEN** the system stores the name on the `User`, attaches the avatar and returns the updated profile with a non-null `avatarUrl`

### Requirement: Units endpoint

The system SHALL expose `GET /api/v1/private/units` returning `{ data: [{ id, name, organization: { id, name } }] }` with the units where the authenticated user's `Person` in the current organization has an active `UnitOccupancy` or `UnitOwnership`.

#### Scenario: Only related units are listed

- **GIVEN** the user's `Person` has an active occupancy on unit U1 and no relationship with U2 in the same property
- **WHEN** the user requests `GET /units`
- **THEN** the response contains U1 and not U2

#### Scenario: Visitor has no units

- **GIVEN** a user whose only relationship with O is a `visitor` membership
- **WHEN** the user requests `GET /units`
- **THEN** the response is `200` with an empty list

### Requirement: Organization detail endpoints

The system SHALL expose `GET /api/v1/private/organization/:id` returning `{ data: { name, cover, logo, residentialProperties: [{ id, name, propertyType, address: { addressLine, city, region }, units: [{ id, code, displayName, unitType, isOwner, occupancyType }], organizationId }] } }` and `GET /api/v1/private/organization/:id/residential_property/:property_id` returning one property with the same shape, both restricted to properties and units where the user has an active relationship.

#### Scenario: Organization id must match the tenant

- **GIVEN** an authenticated user in O
- **WHEN** the user requests `GET /organization/:id` with the id of another organization
- **THEN** the system returns `404`

#### Scenario: Owner flag reflects ownership

- **GIVEN** the user's `Person` owns unit U and occupies unit V
- **WHEN** the user requests the organization detail
- **THEN** U has `isOwner: true` and V has `isOwner: false` with its `occupancyType`

### Requirement: Unit visits by day

The system SHALL expose `GET /api/v1/private/units/:unit_id/visits?day=YYYY-MM-DD` returning `{ data: [{ id, visitor_name, status, scheduled_at, checked_in_at, checked_out_at }] }` for visits of that unit whose `scheduled_at` falls on that day in the property's time zone, under the same resident guard as visit creation.

#### Scenario: Resident lists a day's visits

- **GIVEN** a resident allowed to create visits for U with two visits on 2026-09-20 and one on 2026-09-21
- **WHEN** the resident requests `GET /units/U/visits?day=2026-09-20`
- **THEN** the response lists exactly the two visits of that day

#### Scenario: Invalid day is rejected

- **WHEN** the resident requests with `day=2026-13-40`
- **THEN** the system returns `422` with a localized error

#### Scenario: Unit from another organization

- **WHEN** the resident requests visits of a unit belonging to another organization
- **THEN** the system returns `404`

### Requirement: Visitor invitations endpoint

The system SHALL expose `GET /api/v1/private/invitations` returning `{ data: [{ id, status, scheduled_at, residential_property_name, unit_identifier, host_name, access_code: null }] }` with the visits where `visitor_person.user_id` equals the authenticated user, scheduled from the start of the current day onwards and not `cancelled`, for users holding the `view_own_visits` capability.

#### Scenario: Visitor sees only own upcoming invitations

- **GIVEN** user V is the visitor of visit A (tomorrow) and visit B (last week), and another user is visitor of visit C (tomorrow)
- **WHEN** V requests `GET /invitations`
- **THEN** the response contains A only

#### Scenario: Response carries no other person's data

- **WHEN** V requests `GET /invitations`
- **THEN** each item includes the host's display name and no document, phone or email of any person

### Requirement: Visit detail endpoint

The system SHALL expose `GET /api/v1/private/units/:unit_id/visits/:id` returning `{ data: { id, status, effective_status, scheduled_at, valid_from, valid_until, checked_in_at, checked_out_at, visitor: { name, email, phone }, can_cancel, can_resend } }`. The visit MUST be resolved through the unit, itself resolved within the current tenant. The response MUST NOT include the visitor's identity document.

#### Scenario: Resident reads a visit of their unit

- **GIVEN** a resident with `authorize_visits` on unit U and an `authorized`, non-expired visit V of U
- **WHEN** they request the detail of V under U
- **THEN** the response is `200` with V's data, `can_cancel: true` and `can_resend: true`
- **AND** no document number appears in the body

#### Scenario: Visit from another unit or tenant

- **WHEN** the visit id belongs to a different unit or to another organization
- **THEN** the response is `404`

#### Scenario: Resident without capability

- **GIVEN** a resident whose occupancy of U has `can_authorize_visits = false`
- **WHEN** they request the detail
- **THEN** the response is `403`

#### Scenario: Flags follow the visit state

- **GIVEN** a `checked_in` visit
- **WHEN** the detail is requested
- **THEN** `can_cancel` and `can_resend` are `false`

### Requirement: Visit cancellation endpoint

The system SHALL expose `DELETE /api/v1/private/units/:unit_id/visits/:id`, cancelling the visit through `Visits::Cancel` with the current user as actor and returning `200 { data: { id, status: "cancelled" } }`.

#### Scenario: Resident cancels an authorized visit

- **GIVEN** an `authorized` visit of the resident's unit
- **WHEN** they send the DELETE
- **THEN** the visit becomes `cancelled`, a `cancelled` history event is recorded with the resident as actor, and the response is `200`

#### Scenario: Visit is no longer cancellable

- **GIVEN** a `checked_in`, `checked_out` or `cancelled` visit
- **WHEN** the DELETE is sent
- **THEN** the response is `422` with a localized error and the visit is unchanged

### Requirement: Resend visitor invitation endpoint

The system SHALL expose `POST /api/v1/private/units/:unit_id/visits/:id/resend_invitation`, returning `200` with the visit detail payload on success.

#### Scenario: Successful resend

- **GIVEN** an `authorized`, non-expired visit with no resend in the last 5 minutes
- **WHEN** the resident sends the POST
- **THEN** the visitor is notified again, the response is `200` and `can_resend` is `false`

#### Scenario: Visit not resendable

- **GIVEN** a visit that is not `authorized`, or whose `valid_until` has passed
- **WHEN** the POST is sent
- **THEN** the response is `422` with a localized error and nothing is sent

#### Scenario: Cooldown

- **GIVEN** the invitation was resent 2 minutes ago
- **WHEN** the POST is sent again
- **THEN** the response is `429` with a `Retry-After` header in seconds and nothing is sent

### Requirement: Concierge properties endpoint

The system SHALL expose `GET /api/v1/private/concierge/properties` returning `{ data: [{ id, name }] }` with the residential properties of the current tenant on which the current user holds `view_authorized_visits`, ordered by name.

#### Scenario: Concierge lists their properties

- **GIVEN** a user with an active concierge assignment on property P
- **WHEN** they request the endpoint
- **THEN** the response is `200` and contains only P

#### Scenario: Resident gets an empty list

- **GIVEN** a resident without staff assignments
- **WHEN** they request the endpoint
- **THEN** the response is `200` with an empty `data`

### Requirement: Concierge operational visit listing

The system SHALL expose `GET /api/v1/private/concierge/visits` requiring `property_id`, accepting `tab` (`authorized` default, `checked_in`, `checked_out`), `q` and `page`, and returning `{ data, counters: { authorized, checked_in, checked_out }, pagination }`. Results MUST be limited to the policy scope and to that single property. Each entry SHALL expose `id`, `status`, `effective_status`, `scheduled_at`, `checked_in_at`, `checked_out_at`, `visitor.name`, `unit.display_name`, `authorized_by_name`, `can_check_in`, `can_check_out`, and MUST NOT expose the visitor's email, phone or document.

#### Scenario: Listing by tab

- **GIVEN** property P with one `authorized` and one `checked_in` visit
- **WHEN** the concierge of P requests `tab=checked_in`
- **THEN** only the `checked_in` visit is returned and `counters` reports `authorized: 1, checked_in: 1`

#### Scenario: Property outside the assignment

- **WHEN** the concierge of P requests `property_id` of property Q, or omits `property_id`
- **THEN** the response is `403`

#### Scenario: No cross-property leakage

- **GIVEN** an `authorized` visit on property Q
- **WHEN** the concierge of P lists P's visits
- **THEN** that visit is not returned nor counted

#### Scenario: Search

- **WHEN** the concierge sends `q` with part of a visitor's name
- **THEN** only matching visits of the requested tab are returned

#### Scenario: Minimal visitor data

- **WHEN** a listing is returned
- **THEN** the body contains no visitor email, phone or document number

### Requirement: Concierge check-in and check-out endpoints

The system SHALL expose `POST /api/v1/private/concierge/visits/:id/check_in` (optional `check_in.vehicle_plate`, `check_in.notes`) and `POST /api/v1/private/concierge/visits/:id/check_out` (optional `check_out.notes`), delegating to `Visits::CheckIn` and `Visits::CheckOut` with the current user as actor, and returning `200` with the updated visit entry.

#### Scenario: Check-in

- **GIVEN** an `authorized`, non-expired visit on the concierge's property
- **WHEN** they POST check_in with a vehicle plate
- **THEN** the visit becomes `checked_in`, the plate is stored in its operational metadata, and the entry returns `can_check_in: false, can_check_out: true`

#### Scenario: Check-out

- **GIVEN** a `checked_in` visit
- **WHEN** the concierge POSTs check_out
- **THEN** the visit becomes `checked_out` and the response is `200`

#### Scenario: Invalid transition

- **WHEN** check_in is sent for a `cancelled` visit, or check_out for an `authorized` one
- **THEN** the response is `422` with a localized error and the visit is unchanged

#### Scenario: Visit out of reach

- **WHEN** the visit belongs to a property or organization the user cannot operate
- **THEN** the response is `404`

#### Scenario: Resident cannot operate

- **WHEN** a resident without staff assignment POSTs check_in on a visit of their own unit
- **THEN** the response is `403` or `404` and the visit is unchanged

### Requirement: Visit authorization and rejection endpoints

The system SHALL expose `POST /api/v1/private/units/:unit_id/visits/:id/authorize` and `POST /api/v1/private/units/:unit_id/visits/:id/reject`, delegating to `Visits::Authorize` and `Visits::Reject` with the current user as actor, and returning `200` with the visit detail payload. The visit detail payload SHALL include `can_authorize` and `can_reject`, both `true` only while the visit is `pending`.

#### Scenario: Resident authorizes a pending visit

- **GIVEN** a `pending` visit of a unit on which the resident holds `authorize_visits`
- **WHEN** they POST authorize
- **THEN** the visit becomes `authorized` with the resident as `authorized_by`, and the response has `can_authorize: false`, `can_reject: false`, `can_cancel: true`

#### Scenario: Resident rejects a pending visit

- **WHEN** they POST reject on a `pending` visit
- **THEN** the visit becomes `rejected` and the response is `200`

#### Scenario: Visit already answered

- **GIVEN** a visit another resident already authorized or rejected
- **WHEN** authorize or reject is POSTed
- **THEN** the response is `422` with a localized error and the visit is unchanged

#### Scenario: No capability or out of reach

- **WHEN** the resident lacks `authorize_visits` on the unit, or the visit belongs to another unit or tenant
- **THEN** the response is `403` or `404` respectively

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

### Requirement: Unit residents endpoint
`GET /api/v1/private/units/:unit_id/residents` SHALL return one entry per person holding a currently valid active occupancy or ownership of the unit. Each entry SHALL carry `id`, `name`, `avatar_url` (or `null`), `relationships` (`"owner"` for an ownership and the occupancy type for an occupancy, without duplicates), `can_authorize_visits` and `is_me`. The entry of the requesting user SHALL come first and the rest SHALL be ordered by name. The payload SHALL NOT include email, phone or document.

#### Scenario: Resident lists the unit
- **WHEN** a member with an active occupancy of the unit requests its residents
- **THEN** the response is `200` with every person with an active relationship, the requester first with `is_me: true`

#### Scenario: Person who owns and occupies
- **WHEN** a person has both an active ownership and an active occupancy of the unit
- **THEN** that person appears once with both relationships

#### Scenario: Ended or inactive relationships
- **WHEN** an occupancy or ownership has ended, has not started, or is not active
- **THEN** it does not contribute to the list

#### Scenario: Visit authorization flag
- **WHEN** a person's active occupancy has `can_authorize_visits`
- **THEN** the entry has `can_authorize_visits: true`; an owner without such an occupancy has `false`

### Requirement: Unit residents are visible only to the unit's own residents
The endpoint SHALL require authentication and an active relationship between the requesting person and the unit.

#### Scenario: No relationship with the unit
- **WHEN** a member of the organization without an active occupancy or ownership of the unit requests its residents
- **THEN** the response is `403`

#### Scenario: Unit of another organization
- **WHEN** the unit does not belong to the current organization
- **THEN** the response is `404`

#### Scenario: Unauthenticated
- **WHEN** the request carries no valid token
- **THEN** the response is `401`

### Requirement: Unit parcels endpoint for residents
`GET /api/v1/private/units/:unit_id/parcels` SHALL return, to a person with an active relationship with the unit, the unit's parcels still waiting (`received`) followed by those withdrawn in the last 30 days, newest first within each group. Each parcel SHALL carry `id`, `delivery_type`, `courier_company`, `tracking_code`, `notes`, `status`, `received_at`, `withdrawn_at`, `withdrawn_by_name` and `unit` (`id`, `name`). The response SHALL also carry `can_withdraw`, true when the requesting person may pick parcels up for that unit.

#### Scenario: Resident lists parcels
- **WHEN** a resident of the unit requests its parcels
- **THEN** the response is `200` with waiting parcels first and `can_withdraw` reflecting their occupancy

#### Scenario: No relationship with the unit
- **WHEN** the requester has no active occupancy or ownership of the unit
- **THEN** the response is `403`

#### Scenario: Unit of another organization
- **WHEN** the unit does not belong to the current organization
- **THEN** the response is `404`

### Requirement: Concierge parcel endpoints
Under `/api/v1/private/concierge`, an actor with `manage_parcels` on a property SHALL be able to: list its parcels with `GET parcels?property_id=&tab=&q=&page=` (`tab` is `received`, the default, or `withdrawn` for the last 30 days; `q` matches unit, courier or tracking code; the response includes `counters` and `pagination`); register one with `POST parcels` (`property_id`, `parcel[unit_id, delivery_type, courier_company, tracking_code, notes]`); read one with `GET parcels/:id`, including `eligible_withdrawers` (`id`, `name`, `avatar_url`); and register its withdrawal with `POST parcels/:id/withdraw` (`person_id`). `GET units?property_id=&q=` SHALL list the property's units (`id`, `name`) for the picker.

#### Scenario: Listing
- **WHEN** the concierge lists the parcels of an operated property
- **THEN** the response is `200` with only that property's parcels of the requested tab

#### Scenario: Property not operated
- **WHEN** `property_id` is missing or names a property where the actor lacks `manage_parcels`
- **THEN** the response is `403`

#### Scenario: Registration
- **WHEN** the concierge posts a valid parcel for a unit of the property
- **THEN** the response is `201` with the parcel

#### Scenario: Unit outside the property
- **WHEN** the posted `unit_id` does not belong to the property
- **THEN** the response is `404`

#### Scenario: Withdrawal
- **WHEN** the concierge posts `withdraw` with an eligible `person_id`
- **THEN** the response is `200` with the parcel as `withdrawn`

#### Scenario: Ineligible person or parcel already withdrawn
- **WHEN** the person is not eligible, or the parcel is not `received`
- **THEN** the response is `422` with a message naming the cause

#### Scenario: Parcel of another property
- **WHEN** the parcel belongs to a property the actor does not operate
- **THEN** the response is `404`

### Requirement: Authenticated password change
`PATCH /api/v1/private/me/password` with `current_password` and `password` SHALL change the authenticated user's password when the current password is correct and the new one satisfies the password policy, answering `204`. The token used for the request SHALL remain valid.

#### Scenario: Password changed
- **WHEN** the current password is correct and the new password is valid
- **THEN** the response is `204`, the new password logs in and the old one does not

#### Scenario: Wrong current password
- **WHEN** the current password is missing or incorrect
- **THEN** the response is `422` with `field: "current_password"` and the password is unchanged

#### Scenario: New password rejected
- **WHEN** the new password fails the policy or equals the current one
- **THEN** the response is `422` with `field: "password"` and a message naming the cause

#### Scenario: Too many attempts
- **WHEN** a user exceeds 5 attempts in 15 minutes
- **THEN** the response is `429` with a `Retry-After` header

#### Scenario: Unauthenticated
- **WHEN** the request carries no valid token
- **THEN** the response is `401`

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
