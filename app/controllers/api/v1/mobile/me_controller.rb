# frozen_string_literal: true

class Api::V1::Mobile::MeController < Api::V1::Mobile::BaseController
  def show
    render json: { data: show_payload }, status: :ok
  end

  def update
    if current_user.update(me_params)
      render json: { data: show_payload }, status: :ok
    else
      render json: { error: current_user.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private

  def show_payload
    phone = if current_user.phone_country_code.present? && current_user.phone_number.present?
      { countryCode: current_user.phone_country_code, number: current_user.phone_number }
    end

    {
      email: current_user.email,
      name: current_user.name,
      dni: current_user.dni,
      phone: phone,
      dateOfBirth: current_user.date_of_birth&.iso8601,
      gender: current_user.gender,
      avatarUrl: current_user.avatar_path
    }
  end

  # `params[:phone]` is inspected before `permit` so an explicit `"phone": null`
  # (clear the stored phone) is distinguishable from the key being absent
  # (leave it untouched) — `permit(phone: ...)` alone drops a null `phone` key
  # entirely rather than reporting it.
  def me_params
    permitted = params.permit(:name, :dateOfBirth, :gender, :avatar, phone: %i[countryCode number])

    attrs = {
      name: permitted[:name],
      date_of_birth: permitted[:dateOfBirth].presence,
      gender: permitted[:gender].presence,
      avatar: permitted[:avatar]
    }.compact

    if params.key?(:phone)
      phone = params[:phone]
      attrs[:phone_country_code] = phone.presence && phone[:countryCode]
      attrs[:phone_number] = phone.presence && phone[:number]
    end

    attrs
  end
end
