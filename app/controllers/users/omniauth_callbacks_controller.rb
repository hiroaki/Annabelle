class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :github

  # OAuthパラメータからロケールを先に保存
  before_action :store_locale_for_redirect

  def github
    auth = request.env["omniauth.auth"]

    if user_signed_in?
      if current_user.linked_with?(auth.provider) && current_user.provider_uid(auth.provider) != auth.uid
        flash[:alert] = I18n.t("devise.omniauth_callbacks.provider.already_linked", provider: OmniAuth::Utils.camelize(auth.provider))
        redirect_to localized_edit_registration_path and return
      else
        current_user.link_with(auth.provider, auth.uid)
        flash[:notice] = I18n.t("devise.omniauth_callbacks.provider.success", provider: OmniAuth::Utils.camelize(auth.provider))
        redirect_to localized_edit_registration_path
      end
    else
      @user = User.from_omniauth(auth)

      if @user&.persisted?
        # 新規ユーザーかどうかをインスタンス変数で管理（セッション不使用）
        @is_new_user = @user.saved_change_to_id?

        sign_in(@user, event: :authentication)
        redirect_to determine_oauth_redirect_path
        flash[:notice] = I18n.t("devise.omniauth_callbacks.provider.success", provider: OmniAuth::Utils.camelize(auth.provider)) if is_navigational_format?
      else
        session["devise.github_data"] = auth.except(:extra)
        redirect_to localized_new_registration_path, alert: I18n.t("devise.omniauth_callbacks.failure", provider: OmniAuth::Utils.camelize(auth.provider))
      end
    end
  end

  def failure
    provider = request.env["omniauth.error.strategy"]&.name&.to_s&.humanize || I18n.t("devise.omniauth_callbacks.unknown_provider")
    redirect_to localized_new_session_path, alert: I18n.t("devise.omniauth_callbacks.failure", provider: provider)
  end

  private

  def locale_service
    @locale_service ||= LocaleService.new(self)
  end

  def store_locale_for_redirect
    Rails.logger.debug "OAuth: All params: #{params.inspect}"
    Rails.logger.debug "OAuth: Omniauth params: #{request.env['omniauth.params']}"

    # OAuth認証パラメータからロケールを取得
    omniauth_params = request.env["omniauth.params"] || {}
    locale_param = params[:lang] || params[:locale] ||
                   omniauth_params["lang"] || omniauth_params["locale"]

    # LocaleServiceを使用してロケールを決定
    @oauth_locale = locale_service.determine_effective_locale(locale_param)

    Rails.logger.debug "OAuth: Final oauth_locale: #{@oauth_locale}"
  end

  def stored_locale
    @oauth_locale if LocaleValidator.valid_locale?(@oauth_locale)
  end

  def localized_path_for_redirect(path_symbol, **options)
    locale = stored_locale || locale_service.determine_effective_locale
    if locale == I18n.default_locale.to_s
      send(path_symbol, **options)
    else
      send(path_symbol, **options.merge(locale: locale))
    end
  end

  def localized_edit_registration_path
    localized_path_for_redirect(:edit_user_registration_path)
  end

  def localized_new_registration_path
    localized_path_for_redirect(:new_user_registration_path)
  end

  def localized_new_session_path
    localized_path_for_redirect(:new_user_session_path)
  end

  def determine_oauth_redirect_path
    if @is_new_user
      # 新規ユーザーはアカウント設定ページへ
      localized_edit_registration_path
    else
      # 既存ユーザーは現在のOAuthコンテキストのロケールを優先
      oauth_locale = stored_locale
      if oauth_locale && oauth_locale != I18n.default_locale.to_s
        root_path(locale: oauth_locale)
      else
        root_path
      end
    end
  end
end
