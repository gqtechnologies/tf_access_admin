class User < ApplicationRecord
  rolify

  has_many :permissions, through: :roles

  acts_as_tenant(:organization)
  belongs_to :organization

  after_create :assign_default_role

  validates :name, presence: true
  validates :dni, presence: true
  validates :language, presence: true, inclusion: { in: Languages::ALL }
  validates :email, uniqueness: { message: "users.validations.email_taken" }

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

  private
  def assign_default_role
    self.add_role(:client, self.organization) if self.roles.blank?
  end
end
