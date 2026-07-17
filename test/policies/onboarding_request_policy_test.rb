# frozen_string_literal: true

require "test_helper"

class OnboardingRequestPolicyTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization

    @super_admin = create_user_for_organization(
      organization: @organization, email: "sa-onboarding@example.test", role: AvailableRoles::SUPER_ADMIN
    )
    @tenant_admin = create_user_for_organization(
      organization: @organization, email: "ta-onboarding@example.test", role: AvailableRoles::TENANT_ADMIN
    )
    @content_manager = create_user_for_organization(
      organization: @organization, email: "cm-onboarding@example.test", role: AvailableRoles::CONTENT_MANAGER
    )
    @client = create_user_for_organization(
      organization: @organization, email: "cl-onboarding@example.test", role: AvailableRoles::CLIENT
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "managing people is required to invite/create" do
    assert OnboardingRequestPolicy.new(@tenant_admin, OnboardingRequest).create?
    assert OnboardingRequestPolicy.new(@content_manager, OnboardingRequest).create?
    refute OnboardingRequestPolicy.new(@client, OnboardingRequest).create?
  end

  test "assigning operational roles is manager-only (manage_staff_assignments)" do
    assert OnboardingRequestPolicy.new(@tenant_admin, OnboardingRequest).assign_role?
    # content_manager manages people but is not a property/staff manager
    refute OnboardingRequestPolicy.new(@content_manager, OnboardingRequest).assign_role?
    refute OnboardingRequestPolicy.new(@client, OnboardingRequest).assign_role?
  end

  test "resolving identity conflicts is super-admin-only" do
    assert OnboardingRequestPolicy.new(@super_admin, OnboardingRequest).resolve_conflict?
    refute OnboardingRequestPolicy.new(@tenant_admin, OnboardingRequest).resolve_conflict?
    refute OnboardingRequestPolicy.new(@content_manager, OnboardingRequest).resolve_conflict?
    refute OnboardingRequestPolicy.new(@client, OnboardingRequest).resolve_conflict?
  end
end
