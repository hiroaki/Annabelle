# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    self.resource = devise_mapping.to.find_for_database_authentication(email: params[resource_name][:email])
    password = params[resource_name][:password].presence

    if password && resource&.valid_password?(password)
      if resource.otp_required_for_login
        # セッションに一時的にユーザーIDを保持
        session[:otp_user_id] = resource.id
        redirect_to users_otp_verification_path
      else
        set_flash_message!(:notice, :signed_in)
        sign_in(resource_name, resource)
        yield resource if block_given?
        respond_with resource, location: after_sign_in_path_for(resource)
      end
    else
      # WORKAROUND: ここでの warden.authenticate! は、
      # ２画面にわたる 2FA （の１画面目= email + password ）では常に失敗することを期待しています。
      # そのストラテジー two_factor_authenticatable の手続きに従ってエラー遷移になることを意図しています。
      # `throw :warden, message: :invalid` のように例外のスローでよいとのことですが、
      # そこから戻った画面のフォームに、入力していた値 (email欄) が空にされてしまいます。
      # warden.authenticate! で失敗した場合は入力していた値が復帰しています。
      warden.authenticate!(auth_options)
      # throw :warden, message: :invalid
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  def otp_verification
    @user = User.find(session[:otp_user_id])
  end

  def otp_verify
    @user = User.find(session[:otp_user_id])

    if @user.validate_and_consume_otp!(params[:otp_attempt])
      set_flash_message!(:notice, :signed_in)
      sign_in(:user, @user)
      session.delete(:otp_user_id)
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      flash.now[:alert] = "OTPコードが正しくありません"
      render :otp_verification, status: :see_other
    end
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
