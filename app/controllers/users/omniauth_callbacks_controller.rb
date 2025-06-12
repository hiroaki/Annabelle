class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # OAuth特例処理: 明示的ロケール必須化の例外
  skip_before_action :set_locale
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
        redirect_to localized_new_registration_path, alert: I18n.t("devise.omniauth_callbacks.failure", kind: OmniAuth::Utils.camelize(auth.provider))
      end
    end
  end

  def failure
    # エラー情報を取得
    error_strategy = request.env["omniauth.error.strategy"]
    error_type = request.env["omniauth.error.type"]

    # プロバイダー名を適切に取得
    provider = if error_strategy&.name
                 OmniAuth::Utils.camelize(error_strategy.name.to_s)
               else
                 I18n.t("devise.omniauth_callbacks.unknown_provider")
               end

    # ロケールを決定してからリダイレクト
    effective_locale = locale_service.determine_effective_locale

    # I18n補間エラーを回避するため、安全な方法でメッセージを生成
    begin
      alert_message = I18n.t("devise.omniauth_callbacks.failure", kind: provider)
    rescue I18n::MissingInterpolationArgument
      # providerパラメータが問題ある場合はフォールバックメッセージを使用
      alert_message = I18n.t("devise.omniauth_callbacks.failure_fallback")
    end

    redirect_to new_user_session_path(locale: effective_locale), alert: alert_message
  end

  private

  def locale_service
    @locale_service ||= LocaleService.new(self)
  end

  def store_locale_for_redirect
    # OAuth認証パラメータからロケールを取得
    omniauth_params = request.env["omniauth.params"] || {}
    locale_param = params[:lang] || params[:locale] ||
                   omniauth_params["lang"] || omniauth_params["locale"]

    # LocaleServiceを使用してロケールを決定
    @oauth_locale = locale_service.determine_effective_locale(locale_param)
  end

  def stored_locale
    @oauth_locale if LocaleValidator.valid_locale?(@oauth_locale)
  end

  def localized_path_for_redirect(path_symbol, **options)
    locale = stored_locale || locale_service.determine_effective_locale
    # ステップ3: 明示的ロケール必須化により、常にロケールを含める
    send(path_symbol, **options.merge(locale: locale))
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
      # 既存ユーザーはOAuthコンテキストのロケール付きルートへ
      oauth_locale = stored_locale || locale_service.determine_effective_locale
      # ステップ3: 明示的ロケール必須化により、常にロケールを含める
      root_path(locale: oauth_locale)
    end
  end
end
