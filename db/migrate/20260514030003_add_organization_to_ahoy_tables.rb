# frozen_string_literal: true

# Adds tenant scoping to Ahoy tables. Without `organization_id`, super admins
# would see analytics events from every organization simultaneously.
#
# Ahoy::Store must be configured to populate this column on every visit/event
# (typically inside `app/controllers/concerns/ahoy_visits.rb` and
# `app/services/ahoy_store_with_tenant.rb`).
class AddOrganizationToAhoyTables < ActiveRecord::Migration[8.1]
  def change
    add_reference :ahoy_visits,
                  :organization,
                  type: :uuid,
                  foreign_key: { to_table: :organizations },
                  null: true,
                  index: true

    add_index :ahoy_visits,
              [ :organization_id, :started_at ],
              name: "index_ahoy_visits_on_org_started_at"

    add_reference :ahoy_events,
                  :organization,
                  type: :uuid,
                  foreign_key: { to_table: :organizations },
                  null: true,
                  index: true

    add_index :ahoy_events,
              [ :organization_id, :name, :time ],
              name: "index_ahoy_events_on_org_name_time"
  end
end
