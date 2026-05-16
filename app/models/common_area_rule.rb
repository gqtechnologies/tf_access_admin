# frozen_string_literal: true

# == Schema Information
#
# Table name: common_area_rules
#
#  id              :uuid             not null, primary key
#  metadata        :jsonb            not null
#  position        :integer
#  rule_type       :string           not null
#  value_int       :integer
#  value_text      :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  common_area_id  :uuid             not null
#  organization_id :uuid             not null
#
# Indexes
#
#  index_common_area_rules_on_common_area_id     (common_area_id)
#  index_common_area_rules_on_metadata           (metadata) USING gin
#  index_common_area_rules_on_org_rule_type      (organization_id,rule_type)
#  index_common_area_rules_on_organization_id    (organization_id)
#  index_common_area_rules_unique_per_area_type  (organization_id,common_area_id,rule_type) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (common_area_id => common_areas.id)
#  fk_rails_...  (organization_id => organizations.id)
#
class CommonAreaRule < ApplicationRecord
  include TenantScopedAssociations

  acts_as_tenant :organization

  # Known rule keys. Keep in sync with documentation. Storing free strings is
  # allowed for forward compatibility but new rules should be added here.
  RULE_MAX_GUESTS              = "max_guests"
  RULE_MAX_DURATION_MINUTES    = "max_duration_minutes"
  RULE_MIN_ADVANCE_HOURS       = "min_advance_hours"
  RULE_MAX_RESERVATIONS_MONTH  = "max_reservations_per_month"
  RULE_OPENS_AT                = "opens_at"            # value_text "HH:MM"
  RULE_CLOSES_AT               = "closes_at"           # value_text "HH:MM"
  RULE_ALLOWED_DAYS            = "allowed_days"        # value_text "MO,TU,WE,..."
  RULE_REQUIRES_DEPOSIT        = "requires_deposit"    # value_int 0/1
  RULE_DEPOSIT_AMOUNT_CENTS    = "deposit_amount_cents"
  RULE_NOTES                   = "notes"               # value_text

  KNOWN_RULE_TYPES = [
    RULE_MAX_GUESTS,
    RULE_MAX_DURATION_MINUTES,
    RULE_MIN_ADVANCE_HOURS,
    RULE_MAX_RESERVATIONS_MONTH,
    RULE_OPENS_AT,
    RULE_CLOSES_AT,
    RULE_ALLOWED_DAYS,
    RULE_REQUIRES_DEPOSIT,
    RULE_DEPOSIT_AMOUNT_CENTS,
    RULE_NOTES
  ].freeze

  belongs_to :organization
  belongs_to :common_area

  validates :rule_type,
            presence: true,
            length: { maximum: 64 },
            uniqueness: { scope: [ :organization_id, :common_area_id ] }
  validate  :at_least_one_value_present
  validates_same_tenant :common_area

  scope :known, -> { where(rule_type: KNOWN_RULE_TYPES) }

  def value
    value_int.nil? ? value_text : value_int
  end

  private

  def at_least_one_value_present
    return if value_int.present? || value_text.present?

    errors.add(:base, :value_required)
  end
end
