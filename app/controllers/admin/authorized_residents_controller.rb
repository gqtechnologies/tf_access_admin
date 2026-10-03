# frozen_string_literal: true

# The administration's queue of authorized people for one property: proposals
# to approve or reject, approved people (revocable) and the history. Each
# decision is pushed to the resident who proposed the person.
class Admin::AuthorizedResidentsController < AdminController
  include ManagedPropertyContext

  CAPABILITY = Authorization::Capabilities::MANAGE_OCCUPANCIES
  TABS = %w[pending active closed].freeze
  DECISIONS = %w[approve reject revoke].freeze

  def index
    authorize AuthorizedResident

    property = active_managed_property(CAPABILITY)
    scoped = property ? policy_scope(AuthorizedResident).joins(:unit).where(units: { residential_property_id: property.id }) : AuthorizedResident.none
    records = apply_tab(scoped)
                .includes(:unit, :authorized_by_person, person: :user)
                .page(@filters[:page])
                .per(@filters[:per_page])

    render inertia: "admin/authorized_residents/index", props: {
      authorized_residents: records.map { |record| serialize(record) },
      pagination: pagination_info(records),
      tab: tab,
      counters: TABS.index_with { |name| apply_tab(scoped, name).count },
      properties: managed_properties_for(CAPABILITY).map { |p| property_summary(p) },
      active_property: property_summary(property)
    }
  end

  DECISIONS.each do |decision|
    define_method(decision) do
      record = policy_scope(AuthorizedResident).find(params[:id])
      AuthorizedResidents::Decide.call(authorized_resident: record, actor: current_user, decision: decision)
      redirect_to admin_authorized_residents_path(property_id: record.unit.residential_property_id, tab: params[:tab].presence)
    rescue AuthorizedResidents::Decide::InvalidTransition, Pundit::NotAuthorizedError, ActiveRecord::RecordNotFound
      redirect_to admin_authorized_residents_path(property_id: params[:property_id], tab: params[:tab].presence),
                  inertia: { errors: { base: [ t("frontend.admin.authorized_residents.errors.invalid") ] } }
    end
  end

  private

  def tab
    TABS.include?(params[:tab].to_s) ? params[:tab].to_s : "pending"
  end

  def apply_tab(scope, name = tab)
    case name
    when "active" then scope.currently_valid.order("authorized_residents.created_at DESC")
    when "closed"
      scope.where(status: [ AuthorizedResidentStatuses::REJECTED, AuthorizedResidentStatuses::REVOKED ])
           .or(scope.where(status: AuthorizedResidentStatuses::ACTIVE).where("authorized_residents.ends_at < ?", Time.zone.now))
           .order("authorized_residents.updated_at DESC")
    else scope.where(status: AuthorizedResidentStatuses::PENDING).order("authorized_residents.created_at")
    end
  end

  def serialize(record)
    {
      id: record.id,
      name: record.person&.display_name,
      document: record.person&.document_number,
      relationship_type: record.relationship_type,
      status: record.status,
      starts_at: record.starts_at,
      ends_at: record.ends_at,
      can_withdraw_parcels: record.can_withdraw_parcels,
      notes: record.notes,
      unit: record.unit.display_name.presence || record.unit.identifier,
      proposed_by_name: record.authorized_by_person&.display_name,
      created_at: record.created_at
    }
  end
end
