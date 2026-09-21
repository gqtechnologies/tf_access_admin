# frozen_string_literal: true

# Idempotent seed data. Safe to run repeatedly with `bin/rails db:seed`.
#
# Creates (or updates) one organization with a tenant admin, one resident who
# can invite visitors to unit 101 of a demo building, one concierge assigned to
# that building, and a set of demo visits for today in every status the mobile
# app handles (pending, authorized, inside, exited). Everything can be
# overridden through environment variables so the same seed serves local
# development and a manual smoke test in staging/production:
#
#   SEED_SUBDOMAIN=edificiod SEED_ADMIN_EMAIL=... bin/rails db:seed
#
# Safety rules:
# * Outside development the seed only runs when SEED_DEMO=1, so `db:prepare`
#   on a fresh production database never creates demo accounts by accident.
# * Outside development the passwords MUST be provided explicitly; there are
#   no default passwords for shared environments.
# * Existing users are never modified: no password reset, no role grant. The
#   seed only provisions accounts it creates itself.
# * Demo visits are tagged in `notes` with "seed:<key>:<date>" and created at
#   most once per day, so re-running the seed on another day refreshes the
#   data without duplicating or touching earlier visits.

development = Rails.env.development?

if !development && ENV["SEED_DEMO"] != "1"
  puts "Seeds skipped (set SEED_DEMO=1 to create the demo organization and users)."
  return
end

subdomain          = ENV.fetch("SEED_SUBDOMAIN", "edificiod")
organization_name  = ENV.fetch("SEED_ORGANIZATION_NAME", "Edificio D")
admin_email        = ENV.fetch("SEED_ADMIN_EMAIL", "admin.prueba@gmail.com")
resident_email     = ENV.fetch("SEED_RESIDENT_EMAIL", "residente.prueba@gmail.com")
admin_password     = ENV["SEED_ADMIN_PASSWORD"].presence || (development ? "Admin1234@" : nil)
resident_password  = ENV["SEED_RESIDENT_PASSWORD"].presence || (development ? "Resident1@" : nil)
concierge_email    = ENV.fetch("SEED_CONCIERGE_EMAIL", "conserje.prueba@gmail.com")
concierge_password = ENV["SEED_CONCIERGE_PASSWORD"].presence || (development ? "Conserje1@" : nil)
# Receives the real invitation emails (authorize / resend from the app): point
# it at an inbox you can read.
visitor_email      = ENV.fetch("SEED_VISITOR_EMAIL", "visitante.prueba@gmail.com")

if admin_password.blank? || resident_password.blank? || concierge_password.blank?
  abort "Seeds aborted: set SEED_ADMIN_PASSWORD, SEED_RESIDENT_PASSWORD and SEED_CONCIERGE_PASSWORD outside development."
end

organization = Organization.find_or_initialize_by(subdomain: subdomain)
organization.name = organization.name.presence || organization_name
organization.plan = organization.plan.presence || Organization::PLAN_PRO
organization.save!

# Returns [user, created]. Never touches an existing account.
find_or_create_user = lambda do |email:, name:, dni:, password:|
  existing = User.find_by(email: email)
  next [ existing, false ] if existing

  user = User.new(email: email, name: name, dni: dni, language: Languages::ES,
                  password: password, password_confirmation: password)
  user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
  user.save!
  [ user, true ]
end

ActsAsTenant.with_tenant(organization) do
  # --- Tenant admin (web panel) -------------------------------------------
  admin, admin_created = find_or_create_user.call(email: admin_email, name: "Admin Prueba", dni: "SEED-ADMIN-1", password: admin_password)
  if admin_created
    admin_person = Accounts::ProvisionTenantIdentity.call(user: admin, organization: organization)
    admin_person.add_role(AvailableRoles::TENANT_ADMIN, organization)
  else
    puts "Admin #{admin.email} already exists: left untouched (no password reset, no role change)."
  end

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
  resident, resident_created = find_or_create_user.call(email: resident_email, name: "Residente Prueba", dni: "SEED-RES-1", password: resident_password)
  if resident_created
    resident_person = Accounts::ProvisionTenantIdentity.call(user: resident, organization: organization)
    UnitOccupancy.find_or_create_by!(organization: organization, person: resident_person, unit: unit) do |o|
      o.occupancy_type       = OccupancyTypes::TENANT
      o.starts_at            = 1.day.ago
      o.status               = OccupancyStatuses::ACTIVE
      o.can_authorize_visits = true
    end
  else
    puts "Resident #{resident.email} already exists: left untouched."
  end

  # --- Concierge assigned to the demo building (mobile front desk) --------
  concierge, concierge_created = find_or_create_user.call(email: concierge_email, name: "Conserje Prueba", dni: "SEED-CON-1", password: concierge_password)
  if concierge_created
    concierge_person = Accounts::ProvisionTenantIdentity.call(user: concierge, organization: organization)
    StaffAssignment.find_or_create_by!(organization: organization, person: concierge_person,
                                       residential_property: property, staff_type: StaffTypes::CONCIERGE) do |a|
      a.status    = StaffAssignment::STATUS_ACTIVE
      a.starts_at = Date.current
    end
  else
    puts "Concierge #{concierge.email} already exists: left untouched."
  end

  # --- Demo visits for today ----------------------------------------------
  # Created directly (not through Visits::Create) so nothing is pushed or
  # emailed while seeding; entry/exit go through the real services so the
  # history and operational metadata look like production data.
  find_or_create_visitor = lambda do |name:, email: nil|
    person = email && People::FindExisting.by_email(organization: organization, email: email)
    next person if person

    person = Person.new(organization: organization, display_name: name,
                        person_type: PersonTypes::NATURAL, status: PersonStatuses::ACTIVE)
    person.contact_email = email if email
    person.save!
    person
  end

  today = Time.zone.today
  created_visits = []

  seed_visit = lambda do |key:, visitor:, status:, scheduled_at:|
    tag = "seed:#{key}:#{today.iso8601}"
    next nil if Visit.exists?(organization: organization, unit: unit, notes: tag)

    authorized = status != VisitStatuses::PENDING
    visit = Visit.create!(
      organization: organization, unit: unit, visitor_person: visitor,
      scheduled_at: scheduled_at, status: status, visit_type: VisitTypes::GUEST, notes: tag,
      created_by: authorized ? resident : admin,
      authorized_by: authorized ? resident : nil,
      authorized_at: authorized ? Time.zone.now : nil
    )
    Visits::RecordEvent.call(visit: visit, event_type: VisitEventTypes::CREATED,
                             from_status: nil, to_status: visit.status, actor: visit.created_by)
    created_visits << "#{key} (#{visitor.display_name})"
    visit
  end

  # Waiting for the resident's answer: approve / reject from the app.
  seed_visit.call(key: "pending", visitor: find_or_create_visitor.call(name: "Visitante Prueba", email: visitor_email),
                  status: VisitStatuses::PENDING, scheduled_at: 2.hours.from_now)
  seed_visit.call(key: "pending-2", visitor: find_or_create_visitor.call(name: "Paula Pendiente"),
                  status: VisitStatuses::PENDING, scheduled_at: 3.hours.from_now)

  # Inside its validity window: detail / resend / cancel for the resident,
  # "register entry" for the concierge.
  seed_visit.call(key: "authorized-now", visitor: find_or_create_visitor.call(name: "Visitante Prueba", email: visitor_email),
                  status: VisitStatuses::AUTHORIZED, scheduled_at: 15.minutes.ago)

  # Not yet valid: the concierge sees it without the entry action.
  seed_visit.call(key: "authorized-later", visitor: find_or_create_visitor.call(name: "Tomás Temprano"),
                  status: VisitStatuses::AUTHORIZED, scheduled_at: 5.hours.from_now)

  # Inside the building: "register exit" for the concierge.
  inside = seed_visit.call(key: "inside", visitor: find_or_create_visitor.call(name: "Andrea Adentro"),
                           status: VisitStatuses::AUTHORIZED, scheduled_at: 45.minutes.ago)
  Visits::CheckIn.call(visit: inside, actor: concierge, vehicle_plate: "SEED01", notes: "Ingreso de prueba") if inside

  # Already left: shows under recent exits.
  exited = seed_visit.call(key: "exited", visitor: find_or_create_visitor.call(name: "Sergio Salida"),
                           status: VisitStatuses::AUTHORIZED, scheduled_at: 90.minutes.ago)
  if exited
    Visits::CheckIn.call(visit: exited, actor: concierge)
    Visits::CheckOut.call(visit: exited, actor: concierge, notes: "Salida de prueba")
  end

  puts <<~MSG
    Seeds listos.
      Organización: #{organization.name} (#{organization.subdomain})
      Admin web:    #{admin.email}#{admin_created ? " (created)" : ""}
      Residente:    #{resident.email}#{resident_created ? " (created)" : ""} — #{property.name}, unidad #{unit.identifier}
      Conserje:     #{concierge.email}#{concierge_created ? " (created)" : ""} — #{property.name}
      Visitas hoy:  #{created_visits.any? ? created_visits.join(", ") : "ya existían para #{today.iso8601}"}
      Invitaciones: los correos de autorizar/reenviar llegan a #{visitor_email}
    Passwords are the ones you provided; they are not printed.
  MSG
end
