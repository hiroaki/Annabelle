module Users::AuthenticateWithOtpTwoFactor
  extend ActiveSupport::Concern

  def authenticate_with_otp_two_factor
    # 2FA利用可能でなければスキップ
    return unless helpers.two_factor_auth_available?

    user = self.resource = find_user

    if user_params[:otp_attempt].present? && session[:otp_user_id]
      authenticate_user_with_otp_two_factor(user)
    elsif user&.valid_password?(user_params[:password])
      prompt_for_otp_two_factor(user)
    end
  end

  private

  def valid_otp_attempt?(user)
    user.validate_and_consume_otp!(user_params[:otp_attempt]) ||
        (user.respond_to?(:invalidate_otp_backup_code!) && user.invalidate_otp_backup_code!(user_params[:otp_attempt]))
  end

  def prompt_for_otp_two_factor(user)
    @user = user
    I18n.locale = LocaleUtils.determine_locale(params, request, user)
    session[:otp_user_id] = user.id
    render 'devise/sessions/two_factor', status: :see_other
  end

  def authenticate_user_with_otp_two_factor(user)
    if valid_otp_attempt?(user)
      session.delete(:otp_user_id)
      remember_me(user) if user_params[:remember_me] == '1'
      user.save!
      I18n.locale = LocaleUtils.determine_locale(params, request, user)
      set_flash_message!(:notice, :signed_in)
      sign_in(user, event: :authentication)
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      I18n.locale = LocaleUtils.determine_locale(params, request, user)
      flash.now[:alert] = I18n.t('devise.sessions.invalid_otp')
      prompt_for_otp_two_factor(user)
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :remember_me, :otp_attempt)
  end

  def find_user
    if session[:otp_user_id]
      User.find(session[:otp_user_id])
    elsif user_params[:email]
      User.find_by(email: user_params[:email])
    end
  end

  def otp_two_factor_enabled?
    # 2FA利用可能でなければfalse
    return false unless helpers.two_factor_auth_available?
    find_user&.otp_required_for_login
  end
end
