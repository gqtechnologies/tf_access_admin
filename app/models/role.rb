# == Schema Information
#
# Table name: roles
#
#  id              :uuid             not null, primary key
#  name            :string
#  resource_type   :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :uuid
#  resource_id     :string
#
# Indexes
#
#  index_roles_on_name                                    (name)
#  index_roles_on_name_and_resource_type_and_resource_id  (name,resource_type,resource_id)
#  index_roles_on_organization_id                         (organization_id)
#  index_roles_on_resource                                (resource_type,resource_id)
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#
class Role < ApplicationRecord
  has_and_belongs_to_many :people, join_table: :people_roles
  # Global roles (e.g. :client, :super_admin) must be allowed without tenant.
  belongs_to :organization, optional: true

  belongs_to :resource,
             polymorphic: true,
             optional: true


  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  validates :name, presence: true, inclusion: { in: AvailableRoles::ALL }
  validate :organization_required_for_non_global_roles

  scopify

  private

  def organization_required_for_non_global_roles
    return if name.blank?
    return if [ AvailableRoles::CLIENT, AvailableRoles::SUPER_ADMIN ].include?(name)
    return if organization.present?
    return if resource_type == "Organization" && resource_id.present?

    errors.add(:organization, :blank)
  end
end
