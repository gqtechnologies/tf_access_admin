class Organization < ApplicationRecord
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
    return nil unless cover.attached?

    Rails.application.routes.url_helpers.rails_blob_path(
      cover,
      only_path: true
    )
  end

  def logo_path
    return nil unless logo.attached?

    Rails.application.routes.url_helpers.rails_blob_path(
      logo,
      only_path: true
    )
  end

  def users_count
    users.where(organization_id: id).count
  end
  
  def self.ransackable_attributes(auth_object = nil)
    ["name", "plan"]
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
