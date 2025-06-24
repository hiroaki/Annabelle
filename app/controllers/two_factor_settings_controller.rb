class TwoFactorSettingsController < ApplicationController
  before_action :authenticate_user!

  # new_two_factor_settings GET /two_factor_settings/new(.:format)
  def new
    if current_user.otp_required_for_login
      flash[:alert] = I18n.t('two_factor_settings.already_enabled')
      return redirect_to dashboard_path
    end

    current_user.generate_two_factor_secret_if_missing!
  end

  # two_factor_settings POST /two_factor_settings(.:format)
  def create
    unless current_user.valid_password?(params_enabling_2fa[:password])
      flash.now[:alert] = I18n.t('two_factor_settings.incorrect_password')
      return render :new
    end

    if current_user.validate_and_consume_otp!(params_enabling_2fa[:code])
      current_user.enable_two_factor!

      flash[:notice] = I18n.t('two_factor_settings.enabled')
      redirect_to edit_two_factor_settings_path
    else
      flash.now[:alert] = I18n.t('two_factor_settings.incorrect_code')
      render :new
    end
  end

  # edit_two_factor_settings GET /two_factor_settings/edit(.:format)
  def edit
    unless current_user.otp_required_for_login
      flash[:alert] = I18n.t('two_factor_settings.enable_first')
      return redirect_to new_two_factor_settings_path
    end

    if current_user.two_factor_backup_codes_generated?
      flash[:alert] = I18n.t('two_factor_settings.backup_codes_already_seen')
      return redirect_to two_factor_authentication_path
    end

    @backup_codes = current_user.generate_otp_backup_codes!
    current_user.save!
  end

  # two_factor_settings DELETE /two_factor_settings(.:format)
  def destroy
    if current_user.disable_two_factor!
      flash[:notice] = I18n.t('two_factor_settings.disabled')
      redirect_to two_factor_authentication_path
    else
      flash[:alert] = I18n.t('two_factor_settings.could_not_disable')
      redirect_back fallback_location: root_path
    end
  end

  private

  def params_enabling_2fa
    params.require(:two_fa).permit(:code, :password)
  end
end
