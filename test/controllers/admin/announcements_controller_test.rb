# frozen_string_literal: true

require "test_helper"

# /admin/announcements — OpenSpec 2026-10-02-announcements.
class Admin::AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper
  include OperationalPolicyTestHelper
  include AnnouncementTestHelper
  include ActiveJob::TestHelper

  setup do
    setup_announcement_world("WA")
    @draft = create_announcement(title: "Borrador")
    @published = create_announcement(status: AnnouncementStatuses::PUBLISHED, title: "Publicado", requires_acknowledgement: true)
    AnnouncementRead.create!(organization: @organization, announcement: @published, person: person_of(@picker),
                             read_at: Time.current, acknowledged_at: Time.current)
    ActsAsTenant.current_tenant = nil
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "admin lists published announcements with read stats and the audience size" do
    sign_in_as(@tenant_admin)
    inertia_get admin_announcements_path(property_id: @property.id)

    assert_response :success
    assert_equal "admin/announcements/index", inertia_component
    props = inertia_props
    assert_equal [ "Publicado" ], props["announcements"].map { |a| a["title"] }
    assert_equal 1, props["announcements"].first["read_count"]
    assert_equal 1, props["announcements"].first["acknowledged_count"]
    assert_equal({ "draft" => 1, "published" => 1, "archived" => 0 }, props["counters"])
    assert_equal 3, props["audience_count"]
  end

  test "drafts tab" do
    sign_in_as(@tenant_admin)
    inertia_get admin_announcements_path(property_id: @property.id, tab: "draft")

    assert_equal [ "Borrador" ], inertia_props["announcements"].map { |a| a["title"] }
  end

  test "create stores a draft for the active property" do
    sign_in_as(@tenant_admin)

    assert_difference "Announcement.count", 1 do
      post admin_announcements_path(property_id: @property.id), params: {
        announcement: { title: "Mantención ascensor", content: "El lunes se revisa.", category: "maintenance", priority: "high" }
      }
    end

    created = Announcement.order(:created_at).last
    assert_equal AnnouncementStatuses::DRAFT, created.status
    assert_equal @property.id, created.residential_property_id
    assert_equal person_of(@tenant_admin).id, created.author_person_id
  end

  test "create without title stores nothing" do
    sign_in_as(@tenant_admin)

    assert_no_difference "Announcement.count" do
      post admin_announcements_path(property_id: @property.id), params: { announcement: { title: "", content: "x" } }
    end

    assert_response :redirect
  end

  test "update edits a draft but not a published announcement" do
    sign_in_as(@tenant_admin)

    patch admin_announcement_path(@draft), params: { announcement: { title: "Editado" } }
    assert_equal "Editado", @draft.reload.title

    patch admin_announcement_path(@published), params: { announcement: { title: "No" } }
    assert_equal "Publicado", @published.reload.title
  end

  test "publish pushes to the residents and archive withdraws it" do
    sign_in_as(@tenant_admin)

    assert_enqueued_jobs 3, only: DeliverPushNotificationJob do
      post publish_admin_announcement_path(@draft)
    end
    assert_equal AnnouncementStatuses::PUBLISHED, @draft.reload.status

    post archive_admin_announcement_path(@draft)
    assert_equal AnnouncementStatuses::ARCHIVED, @draft.reload.status
  end

  test "property admin cannot touch another property's announcements" do
    foreign = ActsAsTenant.with_tenant(@organization) { create_announcement(property: @property_q) }
    ActsAsTenant.current_tenant = nil
    sign_in_as(@property_admin)

    post publish_admin_announcement_path(foreign)

    assert_equal AnnouncementStatuses::DRAFT, foreign.reload.status
  end

  test "concierge and residents are redirected away" do
    [ @concierge, @picker ].each do |user|
      sign_in_as(user)
      get admin_announcements_path

      assert_response :redirect
    end
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "Password1@" } }
  end
end
