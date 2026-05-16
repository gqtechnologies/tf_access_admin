# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :organization
  attribute :user
  attribute :person
end
