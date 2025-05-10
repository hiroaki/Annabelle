class Users::SessionsController < Devise::SessionsController
  include Users::AuthenticateWithOtpTwoFactor

  prepend_before_action :authenticate_with_otp_two_factor,
    if: -> { action_name == 'create' && otp_two_factor_enabled? }

  protect_from_forgery with: :exception, prepend: true, except: :destroy
end
