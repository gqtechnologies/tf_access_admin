# frozen_string_literal: true

module Incidents
  # The administration moves an incident: status, assignee, priority and the
  # resolution. Closing it (resolved or dismissed) requires a resolution and
  # tells whoever reported it.
  class Update
    include Authorization::ActorContext

    class ResolutionRequired < StandardError; end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(incident:, actor:, attributes:)
      @incident = incident
      @actor = actor
      @attributes = attributes.to_h.symbolize_keys.slice(:status, :priority, :assigned_to_person_id, :resolution)
    end

    def call
      with_actor_context do
        raise Pundit::NotAuthorizedError unless IncidentPolicy.new(@actor, @incident).manage?
      end

      person = @actor.person_for(ActsAsTenant.current_tenant)
      notify = false

      @incident.with_lock do
        from = @incident.status
        @incident.assign_attributes(@attributes)
        raise ResolutionRequired if @incident.closed? && @incident.resolution.blank?

        @incident.resolved_at = @incident.closed? ? (@incident.resolved_at || Time.zone.now) : nil
        @incident.save!

        if @incident.status != from
          @incident.incident_status_histories.create!(
            organization: @incident.organization, from_status: from, to_status: @incident.status,
            changed_by_person: person, reason: @incident.closed? ? @incident.resolution : nil
          )
          notify = @incident.reported_by_person.present? && @incident.reported_by_person_id != person&.id
        end
      end

      notify_reporter if notify
      @incident
    end

    private

    def notify_reporter
      notification = Notification.create!(
        organization: @incident.organization,
        recipient_person: @incident.reported_by_person,
        unit: @incident.unit,
        residential_property: @incident.residential_property,
        notifiable: @incident,
        notification_type: NotificationTypes::INCIDENT,
        channel: NotificationChannels::PUSH,
        status: NotificationStatuses::PENDING,
        metadata: { "incident_status" => @incident.status }
      )
      DeliverPushNotificationJob.perform_later(notification.id)
    rescue StandardError => e
      Rails.logger.error("[Incidents::Update] incident=#{@incident.id} #{e.class}: #{e.message}")
    end
  end
end
