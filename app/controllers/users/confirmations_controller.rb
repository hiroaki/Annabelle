# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # user_confirmation POST /:locale/users/confirmation(.:format)
  def create
    @language_switcher_path = new_user_confirmation_path
    super
  end

  # user_confirmation GET /:locale/users/confirmation(.:format)
  def show
    @language_switcher_path = new_user_confirmation_path
    super
  end
end
