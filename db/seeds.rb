# frozen_string_literal: true

# Idempotent seed data. Safe to run repeatedly with `bin/rails db:seed`.
#
# Creates (or updates) one organization with a tenant admin and one resident
# who can invite visitors to unit 101 of a demo building. Everything can be
# overridden through environment variables so the same seed serves local
# development and a manual smoke test in staging/production:
#
#   SEED_SUBDOMAIN=edificiod SEED_ADMIN_EMAIL=... bin/rails db:seed
#
# Outside development the seed only runs when SEED_DEMO=1, so `db:prepare`
# on a fresh production database never creates demo accounts by accident.

if !Rails.env.development? && ENV["SEED_DEMO"] != "1"
  puts "Seeds skipped (set SEED_DEMO=1 to create the demo organization and users)."
  return
end

subdomain          = ENV.fetch("SEED_SUBDOMAIN", "edificiod")
organization_name  = ENV.fetch("SEED_ORGANIZATION_NAME", "Edificio D")
admin_email        = ENV.fetch("SEED_ADMIN_EMAIL", "admin.prueba@gmail.com")
admin_password     = ENV.fetch("SEED_ADMIN_PASSWORD", "Admin1234@")
resident_email     = ENV.fetch("SEED_RESIDENT_EMAIL", "residente.prueba@gmail.com")
resident_password  = ENV.fetch("SEED_RESIDENT_PASSWORD", "Resident1@")

organization = Organization.find_or_initialize_by(subdomain: subdomain)
organization.name = organization.name.presence || organization_name
organization.plan = organization.plan.presence || Organization::PLAN_PRO
organization.save!

upsert_user = lambda do |email:, name:, dni:, password:|
  user = User.find_or_initialize_by(email: email)
  user.assign_attributes(
    name: user.name.presence || name,
    dni: user.dni.presence || dni,
    language: user.language.presence || Languages::ES,
    password: password,
    password_confirmation: password
  )
  user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
  user.save!
  user
end

ActsAsTenant.with_tenant(organization) do
  # --- Tenant admin (web panel) -------------------------------------------
  admin = upsert_user.call(email: admin_email, name: "Admin Prueba", dni: "SEED-ADMIN-1", password: admin_password)
  admin_person = admin.person_for(organization) ||
                 Accounts::ProvisionTenantIdentity.call(user: admin, organization: organization)
  admin_person.add_role(AvailableRoles::TENANT_ADMIN, organization) unless admin_person.has_role?(AvailableRoles::TENANT_ADMIN, organization)

  # --- Demo building and unit --------------------------------------------
  property = ResidentialProperty.find_or_create_by!(organization: organization, name: "Edificio Prueba") do |p|
    p.property_type = PropertyTypes::BUILDING
    p.status        = "active"
    p.country       = "Chile"
    p.timezone      = "America/Santiago"
  end

  unit = Unit.find_or_create_by!(organization: organization, residential_property: property, identifier: "101") do |u|
    u.unit_type = UnitTypes::APARTMENT
    u.status    = UnitStatuses::AVAILABLE
  end

  # --- Resident who can invite visitors (mobile app) ----------------------
  resident = upsert_user.call(email: resident_email, name: "Residente Prueba", dni: "SEED-RES-1", password: resident_password)
  resident_person = resident.person_for(organization) ||
                    Accounts::ProvisionTenantIdentity.call(user: resident, organization: organization)

  UnitOccupancy.find_or_create_by!(organization: organization, person: resident_person, unit: unit) do |o|
    o.occupancy_type       = OccupancyTypes::TENANT
    o.starts_at            = 1.day.ago
    o.status               = OccupancyStatuses::ACTIVE
    o.can_authorize_visits = true
  end

  puts <<~MSG
    Seeds listos.
      Organización: #{organization.name} (#{organization.subdomain})
      Admin web:    #{admin.email} / #{admin_password}
      Residente:    #{resident.email} / #{resident_password} — #{property.name}, unidad #{unit.identifier}
  MSG
end
