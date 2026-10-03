# frozen_string_literal: true

module Incidents
  # Reports an incident on a property. Residents may report on a property where
  # they hold a currently valid occupancy or ownership (naming one of their units
  # or a common area of it, both optional); front-desk staff may report on a
  # property where they hold report_incidents.
  class Report
    include Authorization::ActorContext

    class NotAllowed < StandardError; end

    PERMITTED = %i[category description priority occurred_at].freeze

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(property:, actor:, attributes:, unit: nil, common_area: nil)
      @property = property
      @actor = actor
      @attributes = attributes.to_h.symbolize_keys.slice(*PERMITTED)
      @unit = unit
      @common_area = common_area
    end

    def call
      person = @actor.person_for(ActsAsTenant.current_tenant)
      incident = Incident.new(
        organization: @property.organization,
        residential_property: @property,
        unit: @unit,
        common_area: @common_area,
        reported_by_person: person,
        status: IncidentStatuses::OPEN,
        priority: Priorities::NORMAL,
        occurred_at: Time.zone.now,
        **@attributes.compact_blank
      )
      raise NotAllowed unless allowed?(person, incident)

      ActiveRecord::Base.transaction do
        incident.save!
        incident.incident_status_histories.create!(
          organization: incident.organization, from_status: nil, to_status: incident.status, changed_by_person: person
        )
      end

      incident
    end

    private

    def allowed?(person, incident)
      return true if staff?(incident)
      return false if person.blank?

      resident_unit_ids = Unit.with_active_relationship_for(person, @property.organization)
                              .where(residential_property_id: @property.id).pluck(:id)
      return false if resident_unit_ids.empty?

      # A resident can only name one of their own units.
      @unit.nil? || resident_unit_ids.include?(@unit.id)
    end

    def staff?(incident)
      with_actor_context { IncidentPolicy.new(@actor, incident).report_as_staff? }
    end
  end
end
