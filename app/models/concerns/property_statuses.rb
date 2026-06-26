# frozen_string_literal: true

# Allowed +residential_properties.status+ values (string-backed lifecycle).
#
# - +draft+:      Wizard initiated; configuration in progress.
# - +configured+: Wizard completed; pending explicit activation.
# - +active+:     Operational property that admits normal management.
# - +inactive+:   Temporarily suspended, reversible.
# - +archived+:   Retired property, preserved for history (terminal).
module PropertyStatuses
  DRAFT      = "draft"
  CONFIGURED = "configured"
  ACTIVE     = "active"
  INACTIVE   = "inactive"
  ARCHIVED   = "archived"

  # Statuses that allow section/unit mutations.
  OPERABLE = [ DRAFT, CONFIGURED, ACTIVE ].freeze

  # Statuses introduced by the setup wizard.
  SETUP = [ DRAFT, CONFIGURED ].freeze

  ALL = [
    DRAFT,
    CONFIGURED,
    ACTIVE,
    INACTIVE,
    ARCHIVED
  ].freeze
end
