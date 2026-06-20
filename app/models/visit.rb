# frozen_string_literal: true

# == Schema Information
#
# Table name: visits
#
#  id                      :uuid             not null, primary key
#  authorized_at           :datetime
#  checked_in_at           :datetime
#  checked_out_at          :datetime
#  metadata                :jsonb            not null
#  notes                   :text
#  scheduled_at            :datetime         not null
#  status                  :string           default("pending"), not null
#  valid_from              :datetime         not null
#  valid_until             :datetime
#  visit_type              :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  authorized_by_id        :uuid
#  checked_in_by_id        :uuid
#  checked_out_by_id       :uuid
#  created_by_id           :uuid
#  host_person_id          :uuid             not null
#  organization_id         :uuid             not null
#  property_section_id     :uuid
#  residential_property_id :uuid             not null
#  unit_id                 :uuid             not null
#  visitor_person_id       :uuid             not null
#
# Indexes
#
#  index_visits_on_authorized_by_id                   (authorized_by_id)
#  index_visits_on_checked_in_by_id                   (checked_in_by_id)
#  index_visits_on_checked_out_by_id                  (checked_out_by_id)
#  index_visits_on_created_by_id                      (created_by_id)
#  index_visits_on_host_person_id                     (host_person_id)
#  index_visits_on_metadata                           (metadata) USING gin
#  index_visits_on_org_property_operational_statuses  (organization_id,residential_property_id,status,checked_out_at) WHERE ((status)::text = ANY ((ARRAY['authorized'::character varying, 'checked_in'::character varying, 'checked_out'::character varying])::text[]))
#  index_visits_on_org_property_pending_scheduled_at  (organization_id,residential_property_id,scheduled_at) WHERE ((status)::text = 'pending'::text)
#  index_visits_on_org_property_status_scheduled_at   (organization_id,residential_property_id,status,scheduled_at)
#  index_visits_on_org_unit_scheduled_at              (organization_id,unit_id,scheduled_at)
#  index_visits_on_organization_id                    (organization_id)
#  index_visits_on_property_section_id                (property_section_id)
#  index_visits_on_residential_property_id            (residential_property_id)
#  index_visits_on_unit_id                            (unit_id)
#  index_visits_on_visitor_person_id                  (visitor_person_id)
#
# Foreign Keys
#
#  fk_rails_...  (authorized_by_id => users.id)
#  fk_rails_...  (checked_in_by_id => users.id)
#  fk_rails_...  (checked_out_by_id => users.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (host_person_id => people.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (property_section_id => property_sections.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#  fk_rails_...  (unit_id => units.id)
#  fk_rails_...  (visitor_person_id => people.id)
#
class Visit < ApplicationRecord
  include TenantScopedAssociations
  include VisitStatuses
  include VisitTypes
  include Visit::OperationalMetadata
  include Visit::StateMachine

  acts_as_tenant :organization

  audited only: %i[
    status visit_type scheduled_at valid_from valid_until notes
    visitor_person_id host_person_id unit_id residential_property_id property_section_id
    created_by_id authorized_by_id authorized_at
    checked_in_by_id checked_in_at checked_out_by_id checked_out_at
  ]

  belongs_to :organization
  belongs_to :residential_property
  belongs_to :property_section, optional: true
  belongs_to :unit
  belongs_to :visitor_person, class_name: "Person"
  belongs_to :host_person, class_name: "Person"
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :authorized_by, class_name: "User", optional: true
  belongs_to :checked_in_by, class_name: "User", optional: true
  belongs_to :checked_out_by, class_name: "User", optional: true
  belongs_to :staff_shift, optional: true

  has_many :visit_status_histories, -> { chronological }, dependent: :destroy
  has_many :visit_participants
  has_one  :visit_recurrence, dependent: :destroy

  validates :scheduled_at, :valid_from, presence: true
  validates :status, presence: true, inclusion: { in: VisitStatuses::ALL }
  validates :visit_type, presence: true, inclusion: { in: VisitTypes::ALL }

  validates_same_tenant :residential_property, :property_section, :unit,
                        :visitor_person, :host_person,
                        :created_by, :authorized_by, :checked_in_by, :checked_out_by,
                        :staff_shift

  validate :validity_range_coherent
  validate :location_coherent_with_unit
  validate :host_active_on_unit

  before_validation :denormalize_location_from_unit
  before_validation :assign_validity_defaults
  before_validation :sanitize_metadata_assignment

  scope :operational, -> { where(status: VisitStatuses::OPERATIONAL) }

  def self.host_eligible?(person:, unit:, at: Time.zone.now)
    return false if person.blank? || unit.blank?

    active_ownership?(person:, unit:, at:) || active_occupancy?(person:, unit:, at:)
  end

  def self.active_ownership?(person:, unit:, at: Time.zone.now)
    UnitOwnership
      .where(
        unit_id: unit.id,
        person_id: person.id,
        organization_id: unit.organization_id,
        status: UnitOwnership::STATUS_ACTIVE
      )
      .where("starts_at <= ?", at.to_date)
      .where("ends_at IS NULL OR ends_at >= ?", at.to_date)
      .exists?
  end

  def self.active_occupancy?(person:, unit:, at: Time.zone.now)
    day_start = at.in_time_zone.beginning_of_day
    day_end = at.in_time_zone.end_of_day

    UnitOccupancy
      .where(
        unit_id: unit.id,
        person_id: person.id,
        organization_id: unit.organization_id,
        status: OccupancyStatuses::ACTIVE
      )
      .where("starts_at <= ?", day_end)
      .where("ends_at IS NULL OR ends_at >= ?", day_start)
      .exists?
  end

  private

  def denormalize_location_from_unit
    return if unit.blank?

    self.organization_id ||= unit.organization_id
    self.residential_property_id = unit.residential_property_id
    self.property_section_id = unit.property_section_id
  end

  def assign_validity_defaults
    self.visit_type = VisitTypes::GUEST if visit_type.blank?
    self.valid_from ||= scheduled_at
  end

  def sanitize_metadata_assignment
    self.metadata = self.class.sanitize_metadata(metadata)
  end

  def validity_range_coherent
    return if valid_until.blank? || valid_from.blank?
    return if valid_until >= valid_from

    errors.add(:valid_until, :after_valid_from)
  end

  def location_coherent_with_unit
    return if unit.blank?

    if residential_property_id.present? && residential_property_id != unit.residential_property_id
      errors.add(:residential_property, :incoherent_with_unit)
    end

    section_matches = property_section_id == unit.property_section_id
    section_matches ||= property_section_id.blank? && unit.property_section_id.blank?
    return if section_matches

    errors.add(:property_section, :incoherent_with_unit)
  end

  def host_active_on_unit
    return if host_person.blank? || unit.blank?

    return if self.class.host_eligible?(person: host_person, unit: unit)

    errors.add(:host_person, :inactive_on_unit)
  end
end
