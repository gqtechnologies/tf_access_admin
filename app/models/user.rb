class User < ApplicationRecord
  rolify

  has_many :permissions, through: :roles

  acts_as_tenant(:organization)
  belongs_to :organization


  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def super_admin?
    has_role?(AvailableRoles::SUPER_ADMIN)
  end

  def tenant_admin?(tenant = Current.tenant)
    has_role?(AvailableRoles::TENANT_ADMIN, tenant)
  end
end
