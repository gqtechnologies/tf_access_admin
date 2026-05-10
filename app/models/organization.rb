# == Schema Information
#
# Table name: organizations
#
#  id         :uuid             not null, primary key
#  deleted_at :datetime
#  name       :string
#  plan       :string           default("free"), not null
#  subdomain  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_organizations_on_deleted_at  (deleted_at)
#  index_organizations_on_plan        (plan)
#  index_organizations_on_subdomain   (subdomain) UNIQUE
#
class Organization < ApplicationRecord
  acts_as_paranoid
  resourcify

  PLAN_FREE = "free".freeze
  PLAN_PRO = "pro".freeze
  PLAN_ENTERPRISE = "enterprise".freeze

  enum :plan, {
    free: PLAN_FREE,
    pro: PLAN_PRO,
    enterprise: PLAN_ENTERPRISE
  }, validate: true

  has_many :users
  has_many :roles
  has_one_attached :logo
  has_one_attached :cover

  before_validation :assign_default_plan, on: :create

  before_validation :generate_uuid, on: :create

  validates :plan, presence: true
  validates :plan, inclusion: { in: plans.keys }

  def cover_path
    BlobUrls.url_for(cover)
  end

  def logo_path
    BlobUrls.url_for(logo)
  end

  def users_count
    users.where(organization_id: id).count
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "name", "plan" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end

  def assign_default_plan
    self.plan ||= PLAN_FREE
  end
end
