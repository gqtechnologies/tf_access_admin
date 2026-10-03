# frozen_string_literal: true

module AuthorizedResidents
  # A resident of the unit who may propose authorized people takes one back:
  # a pending request is withdrawn, an approved person loses access now.
  class Withdraw
    class NotAllowed < StandardError; end
    class NotOpen < StandardError; end

    def self.call(authorized_resident:, person:)
      raise NotAllowed unless Propose.can_propose?(person: person, unit: authorized_resident.unit)

      authorized_resident.with_lock do
        raise NotOpen unless [ AuthorizedResidentStatuses::PENDING, AuthorizedResidentStatuses::ACTIVE ].include?(authorized_resident.status)

        authorized_resident.update!(status: AuthorizedResidentStatuses::REVOKED, ends_at: Time.zone.now)
      end

      authorized_resident
    end
  end
end
