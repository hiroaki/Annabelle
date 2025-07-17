# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
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
end
