class Role < ApplicationRecord
  has_and_belongs_to_many :users, :join_table => :users_roles
  # Global roles (e.g. :client, :super_admin) must be allowed without tenant.
  belongs_to :organization, optional: true

  belongs_to :resource,
             :polymorphic => true,
             :optional => true
  

  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true
  
  validates :name, presence: true, inclusion: { in: AvailableRoles::ALL }
  validate :organization_required_for_non_global_roles

  scopify

  private

  def organization_required_for_non_global_roles
    return if name.blank?
    return if [AvailableRoles::CLIENT, AvailableRoles::SUPER_ADMIN].include?(name)
    return if organization.present?
    return if resource_type == "Organization" && resource_id.present?

    errors.add(:organization, :blank)
  end
end
