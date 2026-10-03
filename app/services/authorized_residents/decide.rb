# frozen_string_literal: true

module AuthorizedResidents
  # The administration approves or rejects a proposed authorized person, or
  # revokes an approved one. The resident who proposed them is told.
  class Decide
    include Authorization::ActorContext

    class InvalidTransition < StandardError; end

    TRANSITIONS = {
      approve: [ AuthorizedResidentStatuses::PENDING, AuthorizedResidentStatuses::ACTIVE ],
      reject: [ AuthorizedResidentStatuses::PENDING, AuthorizedResidentStatuses::REJECTED ],
      revoke: [ AuthorizedResidentStatuses::ACTIVE, AuthorizedResidentStatuses::REVOKED ]
    }.freeze

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(authorized_resident:, actor:, decision:)
      @record = authorized_resident
      @actor = actor
      @from, @to = TRANSITIONS.fetch(decision.to_sym)
    end

    def call
      allowed = with_actor_context { AuthorizedResidentPolicy.new(@actor, @record).decide? }
      raise Pundit::NotAuthorizedError unless allowed

      @record.with_lock do
        raise InvalidTransition unless @record.status == @from

        attributes = { status: @to }
        attributes[:ends_at] = Time.zone.now if @to == AuthorizedResidentStatuses::REVOKED
        @record.update!(attributes)
      end

      notify_proposer
      @record
    end

    private

    def notify_proposer
      return if @record.authorized_by_person.blank?

      notification = Notification.create!(
        organization: @record.organization,
        recipient_person: @record.authorized_by_person,
        unit: @record.unit,
        residential_property: @record.unit.residential_property,
        notifiable: @record,
        notification_type: NotificationTypes::AUTHORIZED_PERSON,
        channel: NotificationChannels::PUSH,
        status: NotificationStatuses::PENDING,
        metadata: { "authorized_status" => @record.status }
      )
      DeliverPushNotificationJob.perform_later(notification.id)
    rescue StandardError => e
      Rails.logger.error("[AuthorizedResidents::Decide] record=#{@record.id} #{e.class}: #{e.message}")
    end
  end
end
