# frozen_string_literal: true

# Normalizes the RFC5545-like recurrence rule that used to live in
# `visits.recurring_rule` (jsonb). The legacy column was dropped in
# `DropLegacyRecurringRuleAndRulesJsonb`.
class CreateVisitRecurrences < ActiveRecord::Migration[8.1]
  def change
    create_table :visit_recurrences, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :visit,        null: false, foreign_key: true, type: :uuid

      t.string   :freq,        null: false
      t.integer  :interval,    null: false, default: 1
      t.datetime :dtstart,     null: false
      t.datetime :until_at
      t.integer  :count
      t.string   :byday
      t.string   :bymonthday
      t.string   :bymonth
      t.string   :wkst,        default: "MO", null: false
      t.string   :timezone,    default: "America/Santiago", null: false
      t.jsonb    :metadata,    null: false, default: {}

      t.timestamps
    end

    add_index :visit_recurrences,
              [ :organization_id, :visit_id ],
              unique: true,
              name: "index_visit_recurrences_unique_per_visit"

    add_index :visit_recurrences,
              [ :organization_id, :freq ],
              name: "index_visit_recurrences_on_org_freq"

    add_index :visit_recurrences,
              [ :organization_id, :dtstart ],
              name: "index_visit_recurrences_on_org_dtstart"

    add_index :visit_recurrences, :metadata, using: :gin

    add_check_constraint :visit_recurrences,
                         "interval > 0",
                         name: "visit_recurrences_interval_positive"

    add_check_constraint :visit_recurrences,
                         "count IS NULL OR count > 0",
                         name: "visit_recurrences_count_positive"

    add_check_constraint :visit_recurrences,
                         "until_at IS NULL OR count IS NULL",
                         name: "visit_recurrences_until_or_count"

    add_check_constraint :visit_recurrences,
                         "until_at IS NULL OR until_at >= dtstart",
                         name: "visit_recurrences_until_after_dtstart"

    add_check_constraint :visit_recurrences,
                         "freq IN ('DAILY','WEEKLY','MONTHLY','YEARLY')",
                         name: "visit_recurrences_freq_allowed"
  end
end
