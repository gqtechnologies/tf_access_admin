# frozen_string_literal: true

# == Schema Information
#
# Table name: authorized_residents
#
#  id                       :uuid             not null, primary key
#  can_authorize_visits     :boolean          default(FALSE), not null
#  can_reserve_common_areas :boolean          default(FALSE), not null
#  can_withdraw_parcels     :boolean          default(FALSE), not null
#  ends_at                  :datetime
#  metadata                 :jsonb            not null
#  notes                    :text
#  relationship_type        :string           not null
#  starts_at                :datetime         not null
#  status                   :string           default("pending"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  authorized_by_person_id  :uuid
#  authorized_by_user_id    :uuid
#  organization_id          :uuid             not null
#  person_id                :uuid             not null
#  unit_id                  :uuid             not null
#
# Indexes
#
#  index_authorized_residents_on_metadata                     (metadata) USING gin
#  index_authorized_residents_on_org_authorized_by_person_id  (organization_id,authorized_by_person_id)
#  index_authorized_residents_on_org_person_status            (organization_id,person_id,status)
#  index_authorized_residents_on_org_unit_status              (organization_id,unit_id,status)
#  index_authorized_residents_on_organization_id              (organization_id)
#  index_authorized_residents_on_person_id                    (person_id)
#  index_authorized_residents_on_unit_id                      (unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (authorized_by_person_id => people.id)
#  fk_rails_...  (authorized_by_user_id => users.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (person_id => people.id)
#  fk_rails_...  (unit_id => units.id)
#
class AuthorizedResident < ApplicationRecord
  acts_as_tenant :organization

  belongs_to :organization
  belongs_to :unit
  belongs_to :person
  belongs_to :authorized_by_person, class_name: "Person", optional: true
  belongs_to :authorized_by_user, class_name: "User", optional: true

  validates :relationship_type, presence: true
  validates :starts_at, presence: true
  validates :status, presence: true
end
