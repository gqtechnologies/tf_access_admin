# frozen_string_literal: true

require "test_helper"

# /api/v1/private/announcements — OpenSpec 2026-10-02-announcements.
class Api::V1::Private::AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include AnnouncementTestHelper
  include Devise::Test::IntegrationHelpers

  JSON_HEADERS = { "Accept" => "application/json" }.freeze

  setup do
    setup_announcement_world("AA")
    @published = create_announcement(status: AnnouncementStatuses::PUBLISHED, title: "Asamblea", requires_acknowledgement: true)
    @older = create_announcement(status: AnnouncementStatuses::PUBLISHED, published_at: 2.days.ago, title: "Pintura")
    create_announcement(title: "Borrador")
    create_announcement(status: AnnouncementStatuses::ARCHIVED, published_at: 3.days.ago, title: "Archivado")
    create_announcement(status: AnnouncementStatuses::PUBLISHED, published_at: 5.days.ago, expires_at: 1.day.ago, title: "Vencido")
    @foreign = create_announcement(property: @property_q, status: AnnouncementStatuses::PUBLISHED, title: "Otra propiedad")
    ActsAsTenant.current_tenant = nil
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "residents see only published, unexpired announcements of their property, newest first" do
    request_as(@relative) { get api_v1_private_announcements_path, headers: JSON_HEADERS }

    assert_response :ok
    body = response.parsed_body
    assert_equal [ "Asamblea", "Pintura" ], body["data"].map { |a| a["title"] }
    assert_equal 2, body["unread_count"]

    first = body["data"].first
    assert_equal true, first["requires_acknowledgement"]
    assert_equal false, first["read"]
    assert_equal @property.name, first.dig("residential_property", "name")
  end

  test "owners without occupancy also see them" do
    request_as(@owner) { get api_v1_private_announcements_path, headers: JSON_HEADERS }

    assert_equal 2, response.parsed_body["data"].size
  end

  test "opening one records the read" do
    request_as(@relative) { get api_v1_private_announcement_path(@published), headers: JSON_HEADERS }

    assert_response :ok
    assert_equal true, response.parsed_body.dig("data", "read")
    assert_equal false, response.parsed_body.dig("data", "acknowledged")

    request_as(@relative) { get api_v1_private_announcements_path, headers: JSON_HEADERS }
    assert_equal 1, response.parsed_body["unread_count"]
  end

  test "acknowledge marks read and acknowledged" do
    request_as(@relative) { post acknowledge_api_v1_private_announcement_path(@published), headers: JSON_HEADERS }

    assert_response :ok
    assert_equal true, response.parsed_body.dig("data", "acknowledged")
    read = AnnouncementRead.find_by!(announcement: @published, person: person_of(@relative))
    assert read.read_at.present?
    assert read.acknowledged_at.present?
  end

  test "an announcement without acknowledgement cannot be acknowledged" do
    request_as(@relative) { post acknowledge_api_v1_private_announcement_path(@older), headers: JSON_HEADERS }

    assert_response :unprocessable_entity
  end

  test "another property's announcement is not found" do
    request_as(@relative) { get api_v1_private_announcement_path(@foreign), headers: JSON_HEADERS }

    assert_response :not_found
  end

  test "a member without units sees nothing" do
    request_as(@concierge) { get api_v1_private_announcements_path, headers: JSON_HEADERS }

    assert_response :ok
    assert_empty response.parsed_body["data"]
  end

  test "requires authentication" do
    host! "#{@organization.subdomain}.example.com"
    get api_v1_private_announcements_path, headers: JSON_HEADERS

    assert_response :unauthorized
  end

  private

  def request_as(user)
    host! "#{@organization.subdomain}.example.com"
    sign_in user
    yield
    sign_out user
  end
end
