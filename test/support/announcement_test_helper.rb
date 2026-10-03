# frozen_string_literal: true

require_relative "parcel_test_helper"

# A property with residents (two occupants and an owner) and its admins, for
# announcement tests. Builds on ParcelTestHelper's world.
module AnnouncementTestHelper
  include ParcelTestHelper

  def setup_announcement_world(prefix)
    setup_parcel_world(prefix)

    @tenant_admin = create_user_for_organization(
      organization: @organization, email: "#{prefix.downcase}-admin@example.test", role: AvailableRoles::TENANT_ADMIN
    )
    @property_admin = create_staff_user(
      organization: @organization, email: "#{prefix.downcase}-padmin@example.test",
      staff_type: StaffTypes::MANAGER, property: @property
    )
    ActsAsTenant.current_tenant = @organization
  end

  def create_announcement(property: @property, status: AnnouncementStatuses::DRAFT, published_at: nil, **attrs)
    Announcement.create!(
      organization: @organization,
      residential_property: property,
      author_person: person_of(@tenant_admin),
      title: attrs.delete(:title) || "Corte de agua",
      content: attrs.delete(:content) || "El martes no habrá agua entre 10:00 y 14:00.",
      status: status,
      published_at: published_at || (status == AnnouncementStatuses::PUBLISHED ? 1.hour.ago : nil),
      **attrs
    )
  end
end
