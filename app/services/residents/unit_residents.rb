# frozen_string_literal: true

module Residents
  # People with a currently valid ownership or occupancy of a unit, one entry
  # per person, for GET /api/v1/private/units/:unit_id/residents.
  #
  # Deliberately minimal: name, photo and the kind of relationship — never
  # contact data. +relationships+ holds "owner" for an ownership and the
  # occupancy_type for an occupancy; +can_authorize_visits+ mirrors the
  # occupancy flag only (operational roles are not surfaced here).
  class UnitResidents
    OWNER = "owner"

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(unit:, viewer:)
      @unit   = unit
      @viewer = viewer
    end

    # Returns an Array of Hashes: the viewer first, then by name.
    def call
      entries = {}

      ownerships.each do |ownership|
        entry_for(entries, ownership.person)[:relationships] << OWNER
      end

      occupancies.each do |occupancy|
        entry = entry_for(entries, occupancy.person)
        entry[:relationships] << occupancy.occupancy_type
        entry[:can_authorize_visits] ||= occupancy.can_authorize_visits
      end

      entries.values
             .each { |entry| entry[:relationships].uniq! }
             .sort_by { |entry| [ entry[:is_me] ? 0 : 1, entry[:name].to_s.downcase ] }
    end

    private

    def ownerships
      Authorization::ActiveRelationships.active_ownerships_of_unit(@unit).includes(person: :user)
    end

    def occupancies
      Authorization::ActiveRelationships.active_occupancies_of_unit(@unit).includes(person: :user)
    end

    def entry_for(entries, person)
      entries[person.id] ||= {
        id: person.id,
        name: person.display_name,
        avatar_url: person.user&.avatar_path,
        relationships: [],
        can_authorize_visits: false,
        is_me: person.id == @viewer&.id
      }
    end
  end
end
