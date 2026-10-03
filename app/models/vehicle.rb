# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicles
#
#  id                      :uuid             not null, primary key
#  authorized_from         :datetime
#  authorized_until        :datetime
#  brand                   :string
#  color                   :string
#  deleted_at              :datetime
#  metadata                :jsonb            not null
#  model                   :string
#  plate_number_ciphertext :text
#  plate_number_digest     :string
#  status                  :string           default("active"), not null
#  vehicle_type            :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  organization_id         :uuid             not null
#  person_id               :uuid
#  unit_id                 :uuid
#
# Indexes
#
#  index_vehicles_on_deleted_at                             (deleted_at)
#  index_vehicles_on_org_person                             (organization_id,person_id)
#  index_vehicles_on_org_status                             (organization_id,status)
#  index_vehicles_on_org_unit                               (organization_id,unit_id)
#  index_vehicles_on_organization_id                        (organization_id)
#  index_vehicles_on_person_id                              (person_id)
#  index_vehicles_on_unit_id                                (unit_id)
#  index_vehicles_unique_plate_digest_per_org_when_present  (organization_id,plate_number_digest) UNIQUE WHERE ((deleted_at IS NULL) AND (plate_number_digest IS NOT NULL))
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#  fk_rails_...  (unit_id => units.id)
#
class Vehicle < ApplicationRecord
  include TenantScopedAssociations
  include VehicleTypes

  acts_as_tenant :organization
  acts_as_paranoid

  belongs_to :organization
  belongs_to :person, optional: true
  belongs_to :unit, optional: true

  validates_same_tenant :person, :unit

  validates :vehicle_type, inclusion: { in: VehicleTypes::ALL }, allow_nil: true, if: -> { vehicle_type.present? }

  STATUS_ACTIVE = "active"

  validates :plate_number, presence: true, length: { maximum: 12 }, format: { with: /\A[A-Z0-9]+\z/ }
  validates :brand, :model, :color, length: { maximum: 60 }
  validate :plate_unique_within_organization

  before_validation :sync_plate_digest

  normalizes :brand, :model, :color, with: ->(value) { value.to_s.strip.presence }

  scope :active, -> { where(status: STATUS_ACTIVE) }

  # The plate lives in metadata (like Person#document_number) with a blind
  # index in plate_number_digest for uniqueness and exact lookups;
  # plate_number_ciphertext stays unused until Active Record encryption is set up.
  def plate_number
    @plate_number || metadata["plate_number"]
  end

  def plate_number=(value)
    @plate_number = self.class.normalize_plate(value)
  end

  # "ab-12 34" → "AB1234": the form residents and the front desk type varies.
  def self.normalize_plate(value)
    value.to_s.upcase.gsub(/[^A-Z0-9]/, "").presence
  end

  def self.plate_digest(value)
    normalized = normalize_plate(value)
    normalized && Digest::SHA256.hexdigest(normalized)
  end

  private

  def sync_plate_digest
    return if @plate_number.nil?

    self.metadata = (metadata || {}).merge("plate_number" => @plate_number)
    self.plate_number_digest = self.class.plate_digest(@plate_number)
  end

  def plate_unique_within_organization
    return if plate_number_digest.blank?

    scope = Vehicle.where(organization_id: organization_id, plate_number_digest: plate_number_digest)
    scope = scope.where.not(id: id) if persisted?
    errors.add(:plate_number, :taken) if scope.exists?
  end
end
