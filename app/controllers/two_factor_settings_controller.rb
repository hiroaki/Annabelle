class TwoFactorSettingsController < ApplicationController
  before_action :authenticate_user!

  # new_two_factor_settings GET /two_factor_settings/new(.:format)
  def new
    if current_user.otp_required_for_login
      flash[:alert] = 'Two Factor Authentication is already enabled.'
      return redirect_to user_path(current_user)
    end

    current_user.generate_two_factor_secret_if_missing!
  end

  # two_factor_settings POST /two_factor_settings(.:format)
  def create
    unless current_user.valid_password?(params_enabling_2fa[:password])
      flash.now[:alert] = 'Incorrect password'
      return render :new
    end

    if current_user.validate_and_consume_otp!(params_enabling_2fa[:code])
      current_user.enable_two_factor!

      flash[:notice] = 'Successfully enabled two factor authentication, please make note of your backup codes.'
      redirect_to edit_two_factor_settings_path
    else
      flash.now[:alert] = 'Incorrect Code'
      render :new
    end
  end

  # edit_two_factor_settings GET /two_factor_settings/edit(.:format)
  def edit
    unless current_user.otp_required_for_login
      flash[:alert] = 'Please enable two factor authentication first.'
      return redirect_to new_two_factor_settings_path
    end

    if current_user.two_factor_backup_codes_generated?
      flash[:alert] = 'You have already seen your backup codes.'
      return redirect_to edit_user_registration_path
    end

    @backup_codes = current_user.generate_otp_backup_codes!
    current_user.save!
  end

  # two_factor_settings DELETE /two_factor_settings(.:format)
  def destroy
    if current_user.disable_two_factor!
      flash[:notice] = 'Successfully disabled two factor authentication.'
      redirect_to edit_user_registration_path
    else
      flash[:alert] = 'Could not disable two factor authentication.'
      redirect_back fallback_location: root_path
    end
  end

  private

  def params_enabling_2fa
    params.require(:two_fa).permit(:code, :password)
  end
end
