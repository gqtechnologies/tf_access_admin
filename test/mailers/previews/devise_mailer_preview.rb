# test/mailers/previews/devise_mailer_preview.rb
class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    user = preview_user

    token = user.send(:generate_confirmation_token)
    user.save!(validate: false)

    Devise::Mailer.confirmation_instructions(user, token)
  end

  def reset_password_instructions
    user = preview_user

    token = user.send(:set_reset_password_token)

    Devise::Mailer.reset_password_instructions(user, token)
  end

  private

  def preview_user
    User.first || User.new(
      name: "Usuario Preview",
      email: "preview@example.com",
      dni: "12345678",
      language: "es",
      organization: Organization.first
    )
  end
end