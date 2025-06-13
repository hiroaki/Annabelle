class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :set_locale
  skip_before_action :verify_authenticity_token, only: :github

  def github
    auth = request.env["omniauth.auth"]
    if user_signed_in?
      link_provider_or_alert(auth)
    else
      authenticate_or_register(auth)
    end
  end

  def failure
    provider = extract_provider_name_for_error
    alert = generate_failure_message(provider)
    redirect_to determine_redirect_path(:auth_failure), alert: alert
  end

  private

  # プロバイダーをユーザーにリンクする、または既にリンクしている場合はアラートを表示
  def link_provider_or_alert(auth)
    provider_name = provider_display_name(auth)

    if current_user.linked_with?(auth.provider) && current_user.provider_uid(auth.provider) != auth.uid
      flash[:alert] = I18n.t("devise.omniauth_callbacks.provider.already_linked", provider: provider_name)
    else
      current_user.link_with(auth.provider, auth.uid)
      flash[:notice] = I18n.t("devise.omniauth_callbacks.provider.success", provider: provider_name)
    end

    redirect_to determine_redirect_path(:link_provider, current_user)
  end

  # 認証情報からユーザーを認証または登録する
  # @param [OmniAuth::AuthHash] auth 認証情報
  def authenticate_or_register(auth)
    user = User.from_omniauth(auth)
    provider_name = provider_display_name(auth)

    if user&.persisted?
      sign_in(user, event: :authentication)

      # ユーザーが新規作成されたか既存ユーザーかによってリダイレクト先を変更
      action = user.saved_change_to_id? ? :new_user : :existing_user
      redirect_to determine_redirect_path(action, user)

      flash[:notice] = I18n.t("devise.omniauth_callbacks.provider.success", provider: provider_name) if is_navigational_format?
    else
      session["devise.github_data"] = auth.except(:extra)
      redirect_to determine_redirect_path(:registration_failure),
                  alert: I18n.t("devise.omniauth_callbacks.failure", kind: provider_name)
    end
  end

  # リダイレクト先
  def determine_redirect_path(action, user = nil)
    case action
    when :link_provider, :new_user
      localized_path(:edit_user_registration, user)
    when :existing_user
      localized_path(:root, user)
    when :registration_failure
      localized_path(:new_user_registration, user)
    when :auth_failure
      localized_path(:new_user_session, user)
    else
      localized_path(:root, user)
    end
  end

  # パスにロケールを適用する
  def localized_path(path_name, user = nil)
    locale = oauth_locale_for(user)

    case path_name
    when :edit_user_registration
      edit_user_registration_path(locale: locale)
    when :new_user_registration
      new_user_registration_path(locale: locale)
    when :new_user_session
      new_user_session_path(locale: locale)
    when :root
      root_path(locale: locale)
    else
      root_path(locale: locale)
    end
  end

  # プロバイダー名を取得
  def provider_display_name(auth_or_provider)
    provider = auth_or_provider.is_a?(String) ? auth_or_provider : auth_or_provider&.provider
    OmniAuth::Utils.camelize(provider.to_s)
  end

  # ロケールを決定する
  def oauth_locale_for(user = nil)
    user ||= current_user
    # OAuthLocaleServiceを優先し、結果がなければLocaleServiceにフォールバック
    OAuthLocaleService.new(self, user).determine_oauth_locale[:locale] ||
      LocaleService.new(self, user).determine_effective_locale
  end

  # エラー時のプロバイダー名を抽出
  def extract_provider_name_for_error
    error_strategy = request.env["omniauth.error.strategy"]
    if error_strategy&.name
      OmniAuth::Utils.camelize(error_strategy.name.to_s)
    else
      I18n.t("devise.omniauth_callbacks.unknown_provider")
    end
  end

  # 認証失敗メッセージを生成
  def generate_failure_message(provider)
    I18n.t("devise.omniauth_callbacks.failure", kind: provider)
  rescue I18n::MissingInterpolationArgument
    I18n.t("devise.omniauth_callbacks.failure_fallback")
  end
end
