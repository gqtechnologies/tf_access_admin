# frozen_string_literal: true

# Shared setup for parcel tests: a property with a concierge, a unit and its
# residents with different parcel permissions.
module ParcelTestHelper
  def setup_parcel_world(prefix)
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    Current.reset

    @property   = create_property(@organization, "#{prefix} Property P")
    @property_q = create_property(@organization, "#{prefix} Property Q")
    @unit   = create_unit(@property, "#{prefix}-P-101")
    @unit_q = create_unit(@property_q, "#{prefix}-Q-201")

    @concierge = create_staff_user(
      organization: @organization, email: "#{prefix.downcase}-concierge@example.test",
      staff_type: StaffTypes::CONCIERGE, property: @property
    )
    @picker   = parcel_member("#{prefix.downcase}-picker@example.test", "Ana Picker")
    @relative = parcel_member("#{prefix.downcase}-relative@example.test", "Beto Relative")
    @owner    = parcel_member("#{prefix.downcase}-owner@example.test", "Carla Owner")

    parcel_occupy(@picker, @unit, can_withdraw_parcels: true)
    parcel_occupy(@relative, @unit, type: OccupancyTypes::FAMILY_MEMBER)
    UnitOwnership.create!(
      organization: @organization, person: person_of(@owner), unit: @unit,
      ownership_percentage: 100, starts_at: Date.current, status: UnitOwnership::STATUS_ACTIVE
    )
  end

  def parcel_member(email, name)
    create_user_for_organization(organization: @organization, email: email, role: AvailableRoles::CLIENT, name: name)
  end

  def person_of(user)
    user.person_for(@organization)
  end

  def parcel_occupy(user, unit, type: OccupancyTypes::TENANT, can_withdraw_parcels: false)
    UnitOccupancy.create!(
      organization: @organization, person: person_of(user), unit: unit,
      occupancy_type: type, starts_at: 7.days.ago,
      status: OccupancyStatuses::ACTIVE, can_withdraw_parcels: can_withdraw_parcels
    )
  end

  def create_parcel(unit, status: ParcelStatuses::RECEIVED, received_at: 1.hour.ago, withdrawn_at: nil, **attrs)
    ParcelDelivery.create!(
      organization: @organization, residential_property: unit.residential_property, unit: unit,
      status: status, received_at: received_at, withdrawn_at: withdrawn_at, **attrs
    )
  end
end
