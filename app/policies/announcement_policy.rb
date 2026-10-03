# frozen_string_literal: true

# Authorization for the administration side of +Announcement+: drafting,
# publishing and archiving ride on manage_announcements, resolved against the
# announcement's residential property (property admins on theirs, organization
# admins everywhere). Residents read announcements through the private API,
# which scopes them by unit relationship instead.
class AnnouncementPolicy < ApplicationPolicy
  def index?
    allowed?(:manage_announcements) || any_accessible_property?(:manage_announcements)
  end

  def create?
    manage?
  end

  def update?
    manage? && record.draft?
  end

  def publish?
    manage? && record.draft?
  end

  def archive?
    manage? && record.published?
  end

  class Scope < ApplicationPolicy::Scope
    include PolicyScopeAuthorization

    def resolve
      resolver = authorization_resolver
      return scope.none unless resolver

      return organization_scoped if resolver.allowed?(:manage_announcements)

      property_ids = resolver.profile.property_capabilities
                             .select { |_id, caps| caps.include?(Authorization::Capabilities::MANAGE_ANNOUNCEMENTS) }
                             .keys
      return scope.none if property_ids.empty?

      organization_scoped.where(residential_property_id: property_ids)
    end
  end

  private

  def manage?
    same_organization? && allowed?(:manage_announcements)
  end
end
