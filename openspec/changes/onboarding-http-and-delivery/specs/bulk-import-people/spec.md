# Bulk Import People

## ADDED Requirements

### Requirement: Import pipeline applies row classification

The system SHALL classify each row via the classification service and act by classification: create the person when ready; generate the appropriate onboarding request when invitation or incorporation is required; leave conflicts and review rows unmodified; treat duplicates idempotently; reject invalid rows. It MUST NOT merge identities automatically.

#### Scenario: Ready rows create people; incorporation rows do not duplicate accounts

- **GIVEN** a batch with a new-person row and an existing-account row
- **WHEN** the import runs
- **THEN** the new-person row creates a person
- **AND** the existing-account row produces an incorporation request without creating a new account

#### Scenario: Conflict rows are not applied

- **GIVEN** a row classified as conflict
- **WHEN** the import runs
- **THEN** the system does not create or modify any identity for that row

### Requirement: Import UI surfaces the classification per row

The system SHALL display the classification of each row in the bulk-import UI so a manager can review before or after applying.

#### Scenario: Row states are visible

- **WHEN** a manager reviews an import
- **THEN** each row shows its classification (ready/invitation/incorporation/review/conflict/duplicate/invalid)
