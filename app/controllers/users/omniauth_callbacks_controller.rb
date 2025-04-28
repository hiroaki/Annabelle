class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
  skip_before_action :verify_authenticity_token, only: :github

  def github
    auth = request.env["omniauth.auth"]

    if user_signed_in?
      # 既にサインインしているユーザの場合、GitHub 情報がすでに登録されているかチェック
      if current_user.provider.present? && current_user.uid.present? &&
         (current_user.uid != auth.uid || current_user.provider != auth.provider)
        # 他の GitHub アカウントと既に連携済みの場合は、上書きせずにキャンセル
        flash[:alert] = "既に別の GitHub アカウントと連携されています。変更はキャンセルされました。"
        redirect_to edit_user_registration_path and return
      else
        # 未連携または同一の情報の場合は、連携を実施
        current_user.update(
          provider: auth.provider,
          uid: auth.uid
        )
        flash[:notice] = "GitHub との連携が成功しました。"
        redirect_to edit_user_registration_path
      end
    else
      @user = User.from_omniauth(auth)

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
        set_flash_message(:notice, :success, kind: "github") if is_navigational_format?
      else
        session["devise.github_data"] = auth.except(:extra) # Removing extra as it can overflow some session stores
        redirect_to new_user_registration_url, alert: "GitHub 認証に失敗しました。"
      end
    end
  end

  def failure
    redirect_to root_path
  end
end
