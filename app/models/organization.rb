class Organization < ApplicationRecord
  resourcify
  
  has_many :users
  has_many :roles
  has_one_attached :logo
  has_one_attached :cover


  before_validation :generate_uuid, on: :create


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
  
  def self.ransackable_attributes(auth_object = nil)
    ["name"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
