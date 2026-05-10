# frozen_string_literal: true

# == Schema Information
#
# Table name: icons
#
#  id         :uuid             not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_icons_on_name  (name) UNIQUE
#
class Icon < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { order(:name) }
end
