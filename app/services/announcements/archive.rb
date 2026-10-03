# frozen_string_literal: true

module Announcements
  # Withdraws a published announcement from the residents' list.
  class Archive
    include Authorization::ActorContext

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(announcement:, actor:)
      @announcement = announcement
      @actor = actor
    end

    def call
      with_actor_context do
        raise Pundit::NotAuthorizedError unless AnnouncementPolicy.new(@actor, @announcement).archive?
      end

      @announcement.update!(status: AnnouncementStatuses::ARCHIVED)
      @announcement
    end
  end
end
