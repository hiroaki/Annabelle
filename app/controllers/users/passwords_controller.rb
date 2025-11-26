# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  prepend_before_action :sign_out_if_signed_in, only: [:new]

  # user_password POST /:locale/users/password(.:format)
  def create
    @language_switcher_path = new_user_password_path
    super
  end

  # user_password PATCH /:locale/users/password(.:format)
  # user_password PUT /:locale/users/password(.:format)
  def update
    @language_switcher_path = edit_user_password_path
    super
  end

  private

  def sign_out_if_signed_in
    if user_signed_in?
      sign_out(current_user)
      flash[:notice] = I18n.t('devise.passwords.signed_out_for_reset', default: 'You have been signed out to reset your password.')
    end
  end
end
