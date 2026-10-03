# frozen_string_literal: true

# Leases of a property: register a draft, activate it (which creates the
# tenant's occupancy with the lease's permissions) and terminate it (which
# closes that occupancy). Managed by whoever manages the property's residents.
class Admin::LeaseContractsController < AdminController
  include ManagedPropertyContext

  CAPABILITY = Authorization::Capabilities::MANAGE_OCCUPANCIES
  TABS = %w[draft active terminated].freeze

  before_action :set_lease, only: %i[activate terminate]

  def index
    authorize AuthorizedResident, :index?

    property = active_managed_property(CAPABILITY)
    scoped = property ? leases_of(property) : LeaseContract.none
    leases = scoped.where(status: tab)
                   .includes(:unit, :lessee_person, :lessor_person)
                   .order(starts_at: :desc)
                   .page(@filters[:page])
                   .per(@filters[:per_page])

    render inertia: "admin/lease_contracts/index", props: {
      leases: leases.map { |lease| serialize(lease) },
      pagination: pagination_info(leases),
      tab: tab,
      counters: TABS.index_with { |status| scoped.where(status: status).count },
      properties: managed_properties_for(CAPABILITY).map { |p| property_summary(p) },
      active_property: property_summary(property),
      units: property ? unit_options(property) : []
    }
  end

  def create
    property = active_managed_property(CAPABILITY)
    unit = property&.units&.find_by(id: params.dig(:lease, :unit_id))
    return redirect_with_error(t("frontend.admin.lease_contracts.errors.unit_required"), tab: "draft") unless unit

    LeaseContracts::Create.call(
      unit: unit,
      actor: current_user,
      lessee_params: params.require(:lessee).permit(:name, :email, :document, :phone),
      attributes: params.require(:lease).permit(:lessor_person_id, :starts_at, :ends_at, :can_authorize_visits,
                                                :can_reserve_common_areas, :can_withdraw_parcels)
    )

    redirect_to admin_lease_contracts_path(property_id: property.id, tab: "draft")
  rescue LeaseContracts::Create::InvalidLessor
    redirect_with_error(t("frontend.admin.lease_contracts.errors.invalid_lessor"), tab: "draft")
  rescue Visits::ResolveVisitorPerson::IdentityConflict
    redirect_with_error(t("api.visits.identity_conflict"), tab: "draft")
  rescue ActiveRecord::RecordInvalid => e
    redirect_with_error(e.record.errors.full_messages.to_sentence, tab: "draft")
  rescue ArgumentError
    redirect_with_error(t("frontend.admin.lease_contracts.errors.lessee_required"), tab: "draft")
  end

  def activate
    LeaseContracts::Activate.call(lease: @lease)
    redirect_to list_path("active")
  rescue LeaseContracts::Activate::NotDraft
    redirect_with_error(t("frontend.admin.lease_contracts.errors.not_draft"), tab: "draft")
  rescue ActiveRecord::RecordInvalid => e
    redirect_with_error(e.record.errors.full_messages.to_sentence, tab: "draft")
  end

  def terminate
    LeaseContracts::Terminate.call(lease: @lease, actor: current_user, on: params[:on])
    redirect_to list_path("terminated")
  rescue LeaseContracts::Terminate::NotActive
    redirect_with_error(t("frontend.admin.lease_contracts.errors.not_active"), tab: "active")
  rescue Date::Error
    redirect_with_error(t("frontend.admin.lease_contracts.errors.invalid_date"), tab: "active")
  end

  private

  def set_lease
    @lease = LeaseContract.joins(:unit).where(units: { residential_property_id: managed_properties_for(CAPABILITY).map(&:id) }).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_with_error(t("frontend.admin.lease_contracts.errors.not_found"))
  end

  def leases_of(property)
    LeaseContract.joins(:unit).where(units: { residential_property_id: property.id })
  end

  def tab
    TABS.include?(params[:tab].to_s) ? params[:tab].to_s : "active"
  end

  # Units with their current owners, for the unit and landlord selects.
  def unit_options(property)
    units = property.units.order(:identifier).to_a
    owners = UnitOwnership.where(unit_id: units.map(&:id), status: UnitOwnership::STATUS_ACTIVE)
                          .where("starts_at <= ?", Date.current)
                          .where("ends_at IS NULL OR ends_at >= ?", Date.current)
                          .includes(:person)
                          .group_by(&:unit_id)

    units.map do |unit|
      {
        id: unit.id,
        name: unit.display_name.presence || unit.identifier,
        owners: (owners[unit.id] || []).map { |ownership| { id: ownership.person_id, name: ownership.person.display_name } }
      }
    end
  end

  def serialize(lease)
    {
      id: lease.id,
      status: lease.status,
      unit: lease.unit.display_name.presence || lease.unit.identifier,
      lessee_name: lease.lessee_person&.display_name,
      lessor_name: lease.lessor_person&.display_name,
      starts_at: lease.starts_at,
      ends_at: lease.ends_at,
      can_authorize_visits: lease.can_authorize_visits,
      can_reserve_common_areas: lease.can_reserve_common_areas,
      can_withdraw_parcels: lease.can_withdraw_parcels
    }
  end

  def list_path(tab)
    admin_lease_contracts_path(property_id: @lease&.unit&.residential_property_id || params[:property_id], tab: tab)
  end

  def redirect_with_error(message, tab: params[:tab].presence)
    redirect_to admin_lease_contracts_path({ property_id: @lease&.unit&.residential_property_id || params[:property_id], tab: tab }.compact),
                inertia: { errors: { base: [ message ] } }
  end
end
