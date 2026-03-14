# frozen_string_literal: true

module Admin
  class UserSerializer
    ADMIN_USER_ATTRIBUTES = %i[id name email dni language].freeze

    def self.call(user)
      new(user).as_json
    end

    def initialize(user)
      @user = user
    end

    def as_json(*)
      @user.slice(*ADMIN_USER_ATTRIBUTES).merge(role: role_name).stringify_keys
    end

    private

    def role_name
      @user.roles.first&.name&.to_s
    end
  end
end
