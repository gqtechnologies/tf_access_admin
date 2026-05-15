# frozen_string_literal: true

# Normalizes the configuration that used to live as a free-form jsonb in
# `common_areas.rules`. The legacy column was dropped in
# `DropLegacyRecurringRuleAndRulesJsonb`.
class CreateCommonAreaRules < ActiveRecord::Migration[8.1]
  def change
    create_table :common_area_rules, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :common_area,  null: false, foreign_key: true, type: :uuid

      t.string  :rule_type,  null: false
      t.integer :value_int
      t.text    :value_text
      t.integer :position
      t.jsonb   :metadata,   null: false, default: {}

      t.timestamps
    end

    add_index :common_area_rules,
              [ :organization_id, :common_area_id, :rule_type ],
              unique: true,
              name: "index_common_area_rules_unique_per_area_type"

    add_index :common_area_rules,
              [ :organization_id, :rule_type ],
              name: "index_common_area_rules_on_org_rule_type"

    add_index :common_area_rules, :metadata, using: :gin

    add_check_constraint :common_area_rules,
                         "value_int IS NOT NULL OR value_text IS NOT NULL",
                         name: "common_area_rules_value_present"
  end
end
