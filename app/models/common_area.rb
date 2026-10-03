# frozen_string_literal: true

# == Schema Information
#
# Table name: common_areas
#
#  id                      :uuid             not null, primary key
#  area_type               :string           not null
#  capacity                :integer
#  deleted_at              :datetime
#  metadata                :jsonb            not null
#  name                    :string           not null
#  requires_approval       :boolean          default(TRUE), not null
#  status                  :string           default("active"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  organization_id         :uuid             not null
#  residential_property_id :uuid             not null
#
# Indexes
#
#  idx_on_organization_id_residential_property_id_stat_8348429f7a  (organization_id,residential_property_id,status)
#  index_common_areas_on_deleted_at                                (deleted_at)
#  index_common_areas_on_metadata                                  (metadata) USING gin
#  index_common_areas_on_organization_id                           (organization_id)
#  index_common_areas_on_residential_property_id                   (residential_property_id)
#  index_common_areas_unique_name_per_property_when_active         (organization_id,residential_property_id,name) UNIQUE WHERE (deleted_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#
class CommonArea < ApplicationRecord
  acts_as_paranoid
  include CommonAreaTypes
  include TenantScopedAssociations

  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :residential_property

  validates_same_tenant :residential_property

  STATUS_ACTIVE = "active"
  STATUS_INACTIVE = "inactive"
  STATUSES = [ STATUS_ACTIVE, STATUS_INACTIVE ].freeze

  # The rules the reservation flow enforces (subset of CommonAreaRule::KNOWN_RULE_TYPES).
  ENFORCED_RULES = [
    CommonAreaRule::RULE_OPENS_AT,
    CommonAreaRule::RULE_CLOSES_AT,
    CommonAreaRule::RULE_MAX_DURATION_MINUTES,
    CommonAreaRule::RULE_MIN_ADVANCE_HOURS,
    CommonAreaRule::RULE_MAX_RESERVATIONS_MONTH,
    CommonAreaRule::RULE_NOTES
  ].freeze

  validates :area_type, presence: true, inclusion: { in: CommonAreaTypes::ALL }
  validates :name, presence: true, length: { maximum: 100 }
  validates :status, inclusion: { in: STATUSES }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  normalizes :name, with: ->(value) { value.to_s.strip }

  scope :active, -> { where(status: STATUS_ACTIVE) }

  def active?
    status == STATUS_ACTIVE
  end

  # { "opens_at" => "08:00", "max_duration_minutes" => 120, ... } for the enforced rules present.
  def rules
    common_area_rules.select { |rule| ENFORCED_RULES.include?(rule.rule_type) }
                     .to_h { |rule| [ rule.rule_type, rule.value ] }
  end

  def time_zone
    ActiveSupport::TimeZone[residential_property.timezone.to_s] || Time.zone
  end

  has_many :common_area_reservations, dependent: :restrict_with_error
  has_many :incidents, dependent: :nullify
  has_many :common_area_rules, dependent: :destroy
end
