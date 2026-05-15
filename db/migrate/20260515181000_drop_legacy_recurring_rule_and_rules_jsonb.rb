# frozen_string_literal: true

# Phase 3 of the normalization started by `CreateVisitRecurrences` and
# `CreateCommonAreaRules`. Drops the legacy jsonb columns now that the
# replacement tables exist and no application code reads them.
#
# Confirmed precondition: the database is empty (no Visit/CommonArea rows hold
# meaningful jsonb payload), so no data migration is required.
class DropLegacyRecurringRuleAndRulesJsonb < ActiveRecord::Migration[8.1]
  def up
    if index_exists?(:visits, :recurring_rule, name: "index_visits_on_recurring_rule")
      remove_index :visits, name: "index_visits_on_recurring_rule"
    end
    remove_column :visits, :recurring_rule

    if index_exists?(:common_areas, :rules, name: "index_common_areas_on_rules")
      remove_index :common_areas, name: "index_common_areas_on_rules"
    end
    remove_column :common_areas, :rules
  end

  def down
    add_column :visits, :recurring_rule, :jsonb, null: false, default: {}
    add_index  :visits, :recurring_rule, using: :gin, name: "index_visits_on_recurring_rule"

    add_column :common_areas, :rules, :jsonb, null: false, default: {}
    add_index  :common_areas, :rules, using: :gin, name: "index_common_areas_on_rules"
  end
end
