class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :github

  def github
    auth = request.env['omniauth.auth']

    if user_signed_in?
      user = current_user
      I18n.locale = fetch_oauth_locale(user)
      locale = I18n.locale
      link_provider_or_alert(auth, user, locale)
    else
      user = User.from_omniauth(auth)
      I18n.locale = fetch_oauth_locale(user)
      locale = I18n.locale
      authenticate_or_register(auth, user, locale)
    end
  end

  def failure
    I18n.locale = fetch_oauth_locale
    provider = extract_provider_name_for_error
    alert = generate_failure_message(provider)
    locale = I18n.locale
    redirect_to determine_redirect_path(:auth_failure, locale), alert: alert
  end

  private

  # プロバイダーをユーザーにリンクする、または既にリンクしている場合はアラートを表示
  def link_provider_or_alert(auth, user, locale)
    provider_name = provider_display_name(auth)

    if Authorization.provider_uid_exists?(auth.provider, auth.uid)
      if user.provider_uid(auth.provider) == auth.uid
        # 正常：自身のuserでリンクされている
        flash[:alert] = I18n.t('devise.omniauth_callbacks.provider.already_linked', provider: provider_name)
      else
        # 警戒：他のuserでリンクされている（ただし、flashメッセージでは区別しない）
        flash[:alert] = I18n.t('devise.omniauth_callbacks.provider.already_linked', provider: provider_name)
        logger.warn("AUTHORIZATION_CONFLICT: (provider_uid_exists) provider=#{auth.provider} uid=#{auth.uid} user=#{user.id}")
      end
    else
      authorization = user.link_with(auth.provider, auth.uid)
      if authorization.errors.any?
        # 警戒：未リンクのチェックとリンク処理との間があるため、バリデーションによって ["UIDは既に使用されています"] が検出される可能性もあります。
        flash[:alert] = I18n.t('devise.omniauth_callbacks.provider.already_linked', provider: provider_name)
        error_types = authorization.errors.details.flat_map { |attr, arr| arr.map { |h| "#{attr}:#{h[:error]}" } }.uniq.join(',')
        logger.warn("AUTHORIZATION_CONFLICT: (link_with) provider=#{auth.provider} uid=#{auth.uid} user=#{user.id} error_types=#{error_types}")
      else
        # 正常：リンク成功
        flash[:notice] = I18n.t('devise.omniauth_callbacks.provider.linked', provider: provider_name)
      end
    end

    redirect_to determine_redirect_path(:link_provider, locale)
  end

  # 認証情報からユーザーを認証または登録する
  # @param [OmniAuth::AuthHash] auth 認証情報
  def authenticate_or_register(auth, user, locale)
    provider_name = provider_display_name(auth)

    if user&.persisted?
      sign_in(user, event: :authentication)

      # ユーザーが新規作成されたか既存ユーザーかによってリダイレクト先を変更
      action = user.saved_change_to_id? ? :new_user : :existing_user
      redirect_to determine_redirect_path(action, locale)

      flash[:notice] = I18n.t('devise.omniauth_callbacks.success', provider: provider_name) if is_navigational_format?
    else
      session['devise.github_data'] = auth.except(:extra)
      redirect_to determine_redirect_path(:registration_failure, locale),
                  alert: I18n.t('devise.omniauth_callbacks.failure', kind: provider_name)
    end
  end

  # リダイレクト先
  def determine_redirect_path(action, locale)
    locale ||= I18n.default_locale
    case action
    when :link_provider, :new_user
      edit_user_registration_path(locale: locale)
    when :existing_user
      root_path(locale: locale)
    when :registration_failure
      new_user_registration_path(locale: locale)
    when :auth_failure
      new_user_session_path(locale: locale)
    else
      # :nocov: ここには到達しません（到達した場合はバグです）
      raise ArgumentError, "Unknown redirect action: #{action}"
      # :nocov:
    end
  end

  # ロケールを決定する（params, session, サービスの順で優先）
  def fetch_oauth_locale(user = nil)
    params[:locale] || session[:omniauth_login_locale] ||
      OAuthLocaleService.new(self, user).determine_oauth_locale ||
      LocaleUtils.determine_locale(params, request, user) ||
      I18n.default_locale
  end

  # プロバイダー名を取得
  def provider_display_name(auth_or_provider)
    provider = auth_or_provider.is_a?(String) ? auth_or_provider : auth_or_provider&.provider
    OmniAuth::Utils.camelize(provider.to_s)
  end

  # エラー時のプロバイダー名を抽出
  def extract_provider_name_for_error
    error_strategy = request.env['omniauth.error.strategy']
    if error_strategy&.name
      OmniAuth::Utils.camelize(error_strategy.name.to_s)
    else
      I18n.t('devise.omniauth_callbacks.unknown_provider')
    end
  end

  # 認証失敗メッセージを生成
  def generate_failure_message(provider)
    I18n.t('devise.omniauth_callbacks.failure', kind: provider)
  rescue I18n::MissingInterpolationArgument
    I18n.t('devise.omniauth_callbacks.failure_fallback')
  end
end
