# account-deletion

## Purpose

Lets a user delete their own account from the app, as the App Store and Google Play require, by anonymizing their personal data while the buildings keep their operational history.

## ADDED Requirements

### Requirement: Users delete their own account
An authenticated user SHALL be able to delete their account with `DELETE /api/v1/private/me`, which responds `204`. A super admin SHALL receive `403` and keep their account.

#### Scenario: Resident deletes the account
- **WHEN** a resident sends `DELETE /api/v1/private/me`
- **THEN** the response is `204` and the account is anonymized

#### Scenario: Super admin
- **WHEN** a super admin sends `DELETE /api/v1/private/me`
- **THEN** the response is `403` and nothing changes

### Requirement: The account is anonymized, not destroyed
Deleting an account SHALL keep the User row but replace its name with "Persona eliminada" and its email with `deleted-<id>@deleted.invalid`, clear its document, phone, birthdate, gender, avatar and push token, replace its password with a random one and set `deactivated_at`. The original email SHALL be free to register again.

#### Scenario: Old credentials stop working
- **WHEN** the deleted user tries to sign in with their former email and password
- **THEN** the sign-in fails

#### Scenario: Email reused
- **WHEN** someone signs up with the deleted account's former email
- **THEN** no existing user holds that email

### Requirement: Every person of the user is anonymized
Every Person linked to the user, in every organization, SHALL become "Persona eliminada" with no document, email, phone, birthdate or personal metadata, status `inactive`, no linked user and a revoked membership. Unit ownerships and occupancies SHALL remain until the administration ends them. Visit participants, visitor profiles and the person's audit trail SHALL lose the names and documents they copied.

#### Scenario: History is kept
- **WHEN** a person who withdrew a parcel deletes their account
- **THEN** the parcel still points to that person, now shown as "Persona eliminada"

#### Scenario: Units are kept
- **WHEN** an owner deletes their account
- **THEN** the ownership still exists, held by "Persona eliminada"

#### Scenario: Audit trail redacted
- **WHEN** an account is deleted
- **THEN** no audit of its people still contains their former names

### Requirement: Deactivated users lose API access at once
The private API SHALL reject with `401` any request authenticated as a deactivated user, including tokens issued before the deactivation.

#### Scenario: Token used after deletion
- **WHEN** a token issued before the account was deleted calls the private API
- **THEN** the response is `401`
