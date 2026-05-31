# frozen_string_literal: true

class Admin::PeopleController < AdminController
  before_action :set_person, only: [ :create ]
  before_action :get_person, only: [ :edit, :update, :destroy ]
  before_action :validate_role, only: [ :create, :update ]

  def index
    authorize Person
    @q = policy_scope(Person).ransack(params[:q])
    people = @q.result(distinct: true)
      .order(created_at: :desc)
      .page(@filters[:page])
      .per(@filters[:per_page])

    pagination = pagination_info(people)
    render inertia: "admin/people/index", props: {
      people: people.map { |person| Admin::PersonSerializer.new(person).as_json },
      pagination: pagination
    }, status: :ok
  end

  def new
    authorize Person
    render inertia: "admin/people/new", props: form_props
  end

  def create
    authorize Person

    if @validation_errors || !save_person_with_membership(@person)
      redirect_to new_admin_person_path, inertia: { errors: @person.errors }
    else
      redirect_to admin_people_path
    end
  end

  def edit
    authorize @person

    person_json = Admin::PersonSerializer.new(@person).as_json
    person_json[:role] = person_json[:tenant_role]
    render inertia: "admin/people/edit", props: form_props(person: person_json)
  end

  def update
    authorize @person

    if @validation_errors || !update_person_with_membership(@person)
      redirect_to edit_admin_person_path(@person), inertia: { errors: @person.errors }
    else
      redirect_to edit_admin_person_path(@person)
    end
  end

  def destroy
    authorize @person
    @person.destroy
    redirect_to admin_people_path
  end

  private

  def form_props(person: nil)
    {
      person: person,
      roles: AvailableRoles::TENANT,
      person_types: PersonTypes::ALL,
      statuses: PersonStatuses::ALL,
      linkable_users: linkable_users
    }
  end

  def linkable_users
    policy_scope(User)
      .order(:name)
      .map { |user| { id: user.id, name: user.name, email: user.email } }
  end

  def set_person
    @person = Person.new(person_params)
    @person.organization ||= ActsAsTenant.current_tenant
    @validation_errors = false
  end

  def get_person
    @person = policy_scope(Person).includes(:user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_people_path, inertia: { errors: [ I18n.t("frontend.admin.people.not_found") ] }
  end

  def save_person_with_membership(person)
    Person.transaction do
      person.save!
      ensure_membership!(person)
      apply_role!(person)
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def update_person_with_membership(person)
    Person.transaction do
      person.update!(person_params)
      ensure_membership!(person)
      apply_role!(person)
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def ensure_membership!(person)
    membership = person.organization_membership
    return membership if membership.present?

    membership = OrganizationMembership.create!(organization: person.organization, person: person)
    membership.accept! if membership.may_accept?
    membership
  end

  def apply_role!(person)
    role = params.dig(:person, :role)
    return if role.blank?

    person.set_tenant_role(role)
  end

  def validate_role
    role = params.dig(:person, :role)
    return if role.blank?

    unless AvailableRoles::TENANT.include?(role)
      target = @person || Person.new
      target.errors.add(:role, "admin.people.validations.role_invalid")
      @validation_errors = true
    end
  end

  def person_params
    params.require(:person).permit(
      :first_name,
      :last_name,
      :document_number,
      :email,
      :phone,
      :birthdate
    ).tap do |permitted|
      permitted[:contact_email] = permitted.delete(:email) if permitted.key?(:email)
      permitted[:contact_phone] = permitted.delete(:phone) if permitted.key?(:phone)
    end
  end
end
