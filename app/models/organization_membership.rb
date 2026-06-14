# frozen_string_literal: true

# == Schema Information
#
# Table name: organization_memberships
#
#  id              :uuid             not null, primary key
#  deleted_at      :datetime
#  joined_at       :datetime
#  metadata        :jsonb            not null
#  revoked_at      :datetime
#  status          :string           default("invited"), not null
#  suspended_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :uuid             not null
#  person_id       :uuid             not null
#
# Indexes
#
#  idx_org_memberships_unique_active_invited          (organization_id,person_id) UNIQUE WHERE (((status)::text = ANY (ARRAY[('invited'::character varying)::text, ('active'::character varying)::text])) AND (deleted_at IS NULL))
#  index_organization_memberships_on_deleted_at       (deleted_at)
#  index_organization_memberships_on_metadata         (metadata) USING gin
#  index_organization_memberships_on_organization_id  (organization_id)
#  index_organization_memberships_on_person_id        (person_id)
#  index_organization_memberships_on_status           (status)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#
class OrganizationMembership < ApplicationRecord
  include TenantScopedAssociations

  acts_as_tenant :organization
  acts_as_paranoid

  STATUS_INVITED   = "invited"
  STATUS_ACTIVE    = "active"
  STATUS_SUSPENDED = "suspended"
  STATUS_REVOKED   = "revoked"

  STATUSES = [
    STATUS_INVITED,
    STATUS_ACTIVE,
    STATUS_SUSPENDED,
    STATUS_REVOKED
  ].freeze

  belongs_to :organization
  belongs_to :person

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates_same_tenant :person

  include AASM

  aasm column: :status, whiny_persistence: true do
    state :invited, initial: true
    state :active
    state :suspended
    state :revoked

    event :accept do
      transitions from: :invited, to: :active, after: :stamp_joined_at
    end

    event :suspend do
      transitions from: :active, to: :suspended, after: :stamp_suspended_at
    end

    event :reactivate do
      transitions from: :suspended, to: :active
    end

    event :revoke do
      transitions from: %i[invited active suspended], to: :revoked, after: :stamp_revoked_at
    end
  end

  scope :active_or_invited, -> { where(status: [ STATUS_ACTIVE, STATUS_INVITED ]) }

  private

  def stamp_joined_at
    self.joined_at ||= Time.current
  end

  def stamp_suspended_at
    self.suspended_at = Time.current
  end

  def stamp_revoked_at
    self.revoked_at = Time.current
  end
end
