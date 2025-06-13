class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # OAuth特例処理: 明示的ロケール必須化の例外
  skip_before_action :set_locale
  skip_before_action :verify_authenticity_token, only: :github
  before_action :prepare_oauth_locale

  def github
    auth = request.env["omniauth.auth"]

    if user_signed_in?
      handle_signed_in_user_oauth(auth)
    else
      handle_oauth_authentication(auth)
    end
  end

  def failure
    provider = extract_provider_name_for_error
    effective_locale = locale_service.determine_effective_locale
    alert_message = generate_failure_message(provider)

    redirect_to new_user_session_path(locale: effective_locale), alert: alert_message
  end

  private

  # OAuth認証処理

  def handle_signed_in_user_oauth(auth)
    if current_user.linked_with?(auth.provider) && current_user.provider_uid(auth.provider) != auth.uid
      flash[:alert] = I18n.t("devise.omniauth_callbacks.provider.already_linked", provider: OmniAuth::Utils.camelize(auth.provider))
      redirect_to localized_edit_registration_path and return
    else
      current_user.link_with(auth.provider, auth.uid)
      flash[:notice] = I18n.t("devise.omniauth_callbacks.provider.success", provider: OmniAuth::Utils.camelize(auth.provider))
      redirect_to localized_edit_registration_path
    end
  end

  def handle_oauth_authentication(auth)
    @user = User.from_omniauth(auth)

    if @user&.persisted?
      @is_new_user = @user.saved_change_to_id?
      sign_in(@user, event: :authentication)
      redirect_to determine_oauth_redirect_path
      flash[:notice] = I18n.t("devise.omniauth_callbacks.provider.success", provider: OmniAuth::Utils.camelize(auth.provider)) if is_navigational_format?
    else
      session["devise.github_data"] = auth.except(:extra)
      redirect_to localized_new_registration_path, alert: I18n.t("devise.omniauth_callbacks.failure", kind: OmniAuth::Utils.camelize(auth.provider))
    end
  end

  def determine_oauth_redirect_path
    if @is_new_user
      localized_edit_registration_path
    else
      root_path(locale: determine_final_oauth_locale)
    end
  end

  # ロケール決定処理

  def prepare_oauth_locale
    @oauth_locale_result = oauth_locale_service.determine_oauth_locale
    Rails.logger.info "OAuth locale determined: #{@oauth_locale_result[:locale]} (source: #{@oauth_locale_result[:source]})"
  end

  def determine_final_oauth_locale
    # OAuth開始時の明示的指定 > ユーザー設定 > その他フォールバック
    explicit_sources = ["omniauth_params", "session"]

    if oauth_locale && explicit_sources.include?(oauth_locale_source)
      oauth_locale
    elsif @user&.preferred_language.present? && LocaleValidator.valid_locale?(@user.preferred_language)
      @user.preferred_language
    elsif oauth_locale
      oauth_locale
    else
      locale_service.determine_effective_locale
    end
  end

  def oauth_locale
    @oauth_locale_result&.dig(:locale) if LocaleValidator.valid_locale?(@oauth_locale_result&.dig(:locale))
  end

  def oauth_locale_source
    @oauth_locale_result&.dig(:source)
  end

  # パス生成ヘルパー

  def localized_path_for_redirect(path_symbol, **options)
    locale = oauth_locale || locale_service.determine_effective_locale
    send(path_symbol, **options.merge(locale: locale))
  end

  def localized_edit_registration_path
    localized_path_for_redirect(:edit_user_registration_path)
  end

  def localized_new_registration_path
    localized_path_for_redirect(:new_user_registration_path)
  end

  # エラー処理ヘルパー

  def extract_provider_name_for_error
    error_strategy = request.env["omniauth.error.strategy"]
    if error_strategy&.name
      OmniAuth::Utils.camelize(error_strategy.name.to_s)
    else
      I18n.t("devise.omniauth_callbacks.unknown_provider")
    end
  end

  def generate_failure_message(provider)
    I18n.t("devise.omniauth_callbacks.failure", kind: provider)
  rescue I18n::MissingInterpolationArgument
    I18n.t("devise.omniauth_callbacks.failure_fallback")
  end

  # セッション管理とサービス

  def restore_oauth_locale_from_session
    return nil unless session[:oauth_locale_timestamp]

    if Time.current.to_i - session[:oauth_locale_timestamp] < 600
      locale = session.delete(:oauth_locale)
      session.delete(:oauth_locale_timestamp)
      return { locale: locale } if LocaleValidator.valid_locale?(locale)
    else
      session.delete(:oauth_locale)
      session.delete(:oauth_locale_timestamp)
    end
    nil
  end

  def locale_service
    @locale_service ||= LocaleService.new(self)
  end

  def oauth_locale_service
    @oauth_locale_service ||= OAuthLocaleService.new(self)
  end

  # OAuth認証時の特別なロケール決定ロジックを担当するサブクラス
  class OAuthLocaleService < LocaleService
    def initialize(oauth_controller)
      super(oauth_controller)
      @oauth_controller = oauth_controller
    end

    def determine_oauth_locale
      result = extract_from_omniauth_params ||
               extract_from_session ||
               extract_from_user(current_user) ||
               extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE']) ||
               default_locale

      result
    end

    private

    def extract_from_omniauth_params
      omniauth_params = request.env["omniauth.params"] || {}
      oauth_locale = omniauth_params["lang"] || omniauth_params["locale"]

      if oauth_locale.present? && LocaleValidator.valid_locale?(oauth_locale)
        { locale: oauth_locale, source: "omniauth_params" }
      end
    end

    def extract_from_session
      session_data = @oauth_controller.send(:restore_oauth_locale_from_session)
      return nil unless session_data

      locale = session_data.is_a?(Hash) ? session_data[:locale] : session_data
      if locale
        { locale: locale, source: "session" }
      end
    end

    def extract_from_user(user)
      locale = super(user)
      if locale
        { locale: locale, source: "user_preference" }
      end
    end

    def extract_from_header(header)
      locale = super(header)
      if locale
        { locale: locale, source: "browser_header" }
      end
    end

    def default_locale
      { locale: I18n.default_locale.to_s, source: "default" }
    end
  end
end
