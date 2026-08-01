# frozen_string_literal: true

module Residents
  # Resolves the units a mobile `client_global?` user may invite a visitor for,
  # across every organization the user belongs to.
  #
  # Mirrors the eligibility rule `Residents::VisitContext` enforces per-unit at
  # creation time (create_visits AND authorize_visits), so nothing returned
  # here would then be rejected by the create endpoint.
  class EligibleUnits
    Entry = Data.define(:organization, :unit)

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      candidate_pairs.select { |pair| capable?(pair) }
    end

    private

    attr_reader :user

    # Runs without a tenant on purpose: `Person`/`UnitOccupancy` are
    # `acts_as_tenant`-scoped, but this app does not set `require_tenant`, so an
    # ambient-tenant query here would silently leak across organizations. Going
    # through `user.people` (not tenant-scoped) keeps this safely self-limited
    # to the requesting user's own relationships.
    def candidate_pairs
      ActsAsTenant.without_tenant do
        user.people.includes(:organization, unit_occupancies: :unit).flat_map do |person|
          person.unit_occupancies.active_authorizers.map do |occupancy|
            Entry.new(organization: person.organization, unit: occupancy.unit)
          end
        end
      end
    end

    def capable?(pair)
      ActsAsTenant.with_tenant(pair.organization) do
        resolver = Authorization::Resolver.new(user: user, organization: pair.organization, unit: pair.unit)

        resolver.allowed?(Authorization::Capabilities::CREATE_VISITS) &&
          resolver.allowed?(Authorization::Capabilities::AUTHORIZE_VISITS)
      end
    end
  end
end
