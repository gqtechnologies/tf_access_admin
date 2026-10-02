# frozen_string_literal: true

# Front-desk parcel workflow on the web: listing per property, arrival
# registration and withdrawal. Web counterpart of
# Api::V1::Private::Concierge::ParcelsController — same policy scope and the
# same Parcels::Receive / Parcels::Withdraw services.
#
# Every listing is pinned to one property where the actor holds manage_parcels
# (?property_id=, defaulting to the first one), so lists and counters never mix
# properties.
class Concierge::ParcelsController < AdminController
  TABS = [ ParcelStatuses::RECEIVED, ParcelStatuses::WITHDRAWN ].freeze
  UNIT_OPTIONS_LIMIT = 2000

  before_action :set_parcel, only: :withdraw

  def index
    authorize ParcelDelivery

    scoped = property_scoped_parcels
    parcels = apply_search(apply_tab(scoped))
                .includes(:unit, :withdrawn_by_person)
                .page(@filters[:page])
                .per(@filters[:per_page])

    render inertia: "concierge/parcels/index", props: {
      parcels: parcels.map { |parcel| serialize(parcel) },
      pagination: pagination_info(parcels),
      tab: tab,
      query: search_query,
      counters: { received: scoped.waiting.count, withdrawn: scoped.recently_withdrawn.count },
      properties: operated_properties.map { |property| { id: property.id, name: property.name } },
      active_property: active_property && { id: active_property.id, name: active_property.name },
      units: unit_options,
      delivery_types: DeliveryTypes::ALL
    }
  end

  def create
    return redirect_with_errors({ base: [ t("api.concierge.property_forbidden") ] }) unless active_property

    unit = active_property.units.find_by(id: parcel_params[:unit_id])
    return redirect_with_errors({ unit_id: [ t("frontend.concierge.parcels.errors.unit_required") ] }) unless unit

    Parcels::Receive.call(unit: unit, actor: current_user, attributes: parcel_params.except(:unit_id))

    redirect_to list_path
  rescue ActiveRecord::RecordInvalid => e
    redirect_with_errors(serialize_inertia_errors(e.record))
  rescue Pundit::NotAuthorizedError
    redirect_with_errors({ base: [ t("api.parcels.not_authorized") ] })
  end

  def withdraw
    Parcels::Withdraw.call(parcel: @parcel, actor: current_user, person_id: params[:person_id])

    redirect_to list_path(property_id: @parcel.residential_property_id)
  rescue Parcels::Withdraw::NotWaitingError
    redirect_with_errors({ base: [ t("api.parcels.not_waiting") ] }, property_id: @parcel.residential_property_id)
  rescue Parcels::Withdraw::NotEligibleError
    redirect_with_errors({ base: [ t("api.parcels.not_eligible") ] }, property_id: @parcel.residential_property_id)
  rescue Pundit::NotAuthorizedError
    redirect_with_errors({ base: [ t("api.parcels.not_authorized") ] }, property_id: @parcel.residential_property_id)
  end

  private

  def set_parcel
    @parcel = policy_scope(ParcelDelivery).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_with_errors({ base: [ t("frontend.concierge.parcels.errors.not_found") ] })
  end

  def tab
    TABS.include?(params[:tab].to_s) ? params[:tab].to_s : ParcelStatuses::RECEIVED
  end

  def apply_tab(scope)
    if tab == ParcelStatuses::WITHDRAWN
      scope.recently_withdrawn.order(withdrawn_at: :desc)
    else
      scope.waiting.order(received_at: :desc)
    end
  end

  def search_query
    params.dig(:q, :query).to_s.strip.presence
  end

  def apply_search(scope)
    return scope if search_query.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(search_query)}%"
    scope.joins(:unit).where(
      "units.identifier ILIKE :q OR units.display_name ILIKE :q OR " \
      "parcel_deliveries.courier_company ILIKE :q OR parcel_deliveries.tracking_code ILIKE :q",
      q: pattern
    )
  end

  # Properties where the actor holds manage_parcels: all of them for an
  # organization-wide holder, the assigned ones for front-desk staff.
  def operated_properties
    @operated_properties ||= begin
      profile = Authorization::Resolver.new(user: current_user, organization: Current.organization).profile

      if profile.organization_capabilities.include?(Authorization::Capabilities::MANAGE_PARCELS)
        ResidentialProperty.order(:name).to_a
      else
        ids = profile.property_capabilities
                     .select { |_, caps| caps.include?(Authorization::Capabilities::MANAGE_PARCELS) }
                     .keys
        ResidentialProperty.where(id: ids).order(:name).to_a
      end
    end
  end

  def active_property
    @active_property ||= operated_properties.find { |property| property.id.to_s == params[:property_id].to_s } ||
                         operated_properties.first
  end

  def property_scoped_parcels
    return policy_scope(ParcelDelivery).none unless active_property

    policy_scope(ParcelDelivery).where(residential_property_id: active_property.id)
  end

  def unit_options
    return [] unless active_property

    active_property.units.order(:identifier).limit(UNIT_OPTIONS_LIMIT).map do |unit|
      { id: unit.id, name: unit.display_name.presence || unit.identifier }
    end
  end

  # Waiting rows carry who may pick the parcel up, memoized per unit so a page
  # of parcels for the same unit runs the query once.
  def serialize(parcel)
    Api::Private::ParcelSerializer.new(parcel).as_json.merge(
      eligible_withdrawers: parcel.waiting? ? eligible_withdrawers_for(parcel.unit) : []
    )
  end

  def eligible_withdrawers_for(unit)
    @eligible_withdrawers ||= {}
    @eligible_withdrawers[unit.id] ||= Parcels::EligibleWithdrawers.call(unit: unit).map do |person|
      { id: person.id, name: person.display_name }
    end
  end

  def parcel_params
    params.fetch(:parcel, {}).permit(:unit_id, :delivery_type, :courier_company, :tracking_code, :notes)
  end

  def list_path(property_id: active_property&.id)
    concierge_parcels_path({ property_id: property_id, tab: params[:tab].presence }.compact)
  end

  def redirect_with_errors(errors, property_id: active_property&.id)
    redirect_to list_path(property_id: property_id), inertia: { errors: errors }
  end
end
