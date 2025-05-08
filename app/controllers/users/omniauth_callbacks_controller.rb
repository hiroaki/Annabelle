class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :github

  def github
    auth = request.env["omniauth.auth"]

    if user_signed_in?
      if current_user.linked_with?(auth.provider) && current_user.provider_uid(auth.provider) != auth.uid
        flash[:alert] = I18n.t("devise.omniauth_callbacks.github.already_linked")
        redirect_to edit_user_registration_path and return
      else
        current_user.link_with(auth.provider, auth.uid)
        flash[:notice] = I18n.t("devise.omniauth_callbacks.github.success")
        redirect_to edit_user_registration_path
      end
    else
      @user = User.from_omniauth(auth)

      if @user&.persisted?
        if @user.saved_change_to_id?
          session["user_return_to"] = edit_user_registration_path
        end

        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: "GitHub") if is_navigational_format?
      else
        session["devise.github_data"] = auth.except(:extra)
        redirect_to new_user_registration_path, alert: I18n.t("devise.omniauth_callbacks.github.failure")
      end
    end
  end

  def failure
    redirect_to new_user_session_path
  end
end
