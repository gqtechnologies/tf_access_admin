# frozen_string_literal: true

class Admin::OnboardingRequestsController < AdminController
  before_action :set_request, only: [ :revoke, :resolve_conflict ]

  def index
    authorize OnboardingRequest
    requests = policy_scope(OnboardingRequest)
      .includes(:person)
      .order(created_at: :desc)
      .page(@filters[:page])
      .per(@filters[:per_page])

    render inertia: "admin/onboarding_requests/index", props: {
      onboarding_requests: requests.map { |r| request_json(r) },
      pagination: pagination_info(requests)
    }, status: :ok
  end

  def new
    authorize OnboardingRequest
    render inertia: "admin/onboarding_requests/new", props: {
      relationships: OnboardingRequest::RELATIONSHIPS
    }
  end

  def create
    authorize OnboardingRequest

    result = Accounts::InvitePerson.call(**invite_args)

    if result.conflict?
      redirect_to admin_onboarding_requests_path,
                  inertia: { errors: { base: [ "admin.onboarding_requests.errors.identity_conflict" ] } }
    else
      deliver_invitation(result)
      redirect_to admin_onboarding_requests_path
    end
  end

  def revoke
    authorize @onboarding_request, :revoke?
    @onboarding_request.revoke! if @onboarding_request.may_revoke?
    redirect_to admin_onboarding_requests_path
  end

  def resolve_conflict
    authorize @onboarding_request, :resolve_conflict?
    IdentityConflicts::Resolve.call(
      onboarding_request: @onboarding_request,
      decision: :dismiss,
      resolved_by: current_user.person_for(current_organization)
    )
    redirect_to admin_onboarding_requests_path
  end

  private

  def set_request
    @onboarding_request = policy_scope(OnboardingRequest).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_onboarding_requests_path,
                inertia: { errors: { base: [ "admin.onboarding_requests.errors.not_found" ] } }
  end

  def invite_args
    {
      organization: current_organization,
      email: params.dig(:onboarding_request, :email),
      requested_relationship: params.dig(:onboarding_request, :relationship).presence ||
        OnboardingRequest::RELATIONSHIP_MEMBERSHIP,
      requested_by_person: current_user.person_for(current_organization),
      first_name: params.dig(:onboarding_request, :first_name),
      last_name: params.dig(:onboarding_request, :last_name),
      document_number: params.dig(:onboarding_request, :document_number),
      phone: params.dig(:onboarding_request, :phone)
    }
  end

  def deliver_invitation(result)
    return if result.token.blank?

    OnboardingMailer.with(
      onboarding_request: result.onboarding_request,
      token: result.token
    ).invitation.deliver_later
  end

  def request_json(request)
    {
      id: request.id,
      status: request.status,
      relationship: request.requested_relationship,
      person_name: request.person&.display_name,
      expires_at: request.expires_at,
      created_at: request.created_at
    }
  end

  def current_organization
    Current.organization || ActsAsTenant.current_tenant
  end
end
