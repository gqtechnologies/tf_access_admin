class Organization < ApplicationRecord
  resourcify
  
  has_many :users
  has_many :roles

  before_validation :generate_uuid, on: :create

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
