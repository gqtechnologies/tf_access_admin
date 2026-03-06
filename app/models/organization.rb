class Organization < ApplicationRecord
  has_many :users
  has_many :roles

  before_validation :generate_uuid, on: :create

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
