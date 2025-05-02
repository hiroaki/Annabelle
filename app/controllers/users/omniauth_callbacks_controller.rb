class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
  skip_before_action :verify_authenticity_token, only: :github

  def github
    auth = request.env["omniauth.auth"]

    if user_signed_in?
      if current_user.linked_with?(auth.provider) && current_user.provider_uid(auth.provider) != auth.uid
        flash[:alert] = "既に別の GitHub アカウントと連携されています。変更はキャンセルされました。"
        redirect_to edit_user_registration_path and return
      else
        current_user.link_with(auth.provider, auth.uid)
        flash[:notice] = "GitHub との連携が成功しました。"
        redirect_to edit_user_registration_path
      end
    else
      @user = User.from_omniauth(auth)

      if @user&.persisted?
        if @user.saved_change_to_id?
          session["user_return_to"] = edit_user_registration_path
        end

        sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
        set_flash_message(:notice, :success, kind: "github") if is_navigational_format?
      else
        session["devise.github_data"] = auth.except(:extra) # Removing extra as it can overflow some session stores
        redirect_to new_user_registration_path, alert: "GitHub 認証に失敗しました。"
      end
    end
  end

  def failure
    redirect_to new_user_session_path
  end
end
