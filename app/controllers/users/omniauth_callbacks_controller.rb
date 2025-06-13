class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  OAUTH_LOCALE_SESSION_TTL = 600

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
    locale = effective_locale_for_failure
    alert = generate_failure_message(provider)
    redirect_to new_user_session_path(locale: locale), alert: alert
  end

  private

  def link_provider_or_alert(auth)
    if current_user.linked_with?(auth.provider) && current_user.provider_uid(auth.provider) != auth.uid
      flash[:alert] = I18n.t("devise.omniauth_callbacks.provider.already_linked", provider: OmniAuth::Utils.camelize(auth.provider))
    else
      current_user.link_with(auth.provider, auth.uid)
      flash[:notice] = I18n.t("devise.omniauth_callbacks.provider.success", provider: OmniAuth::Utils.camelize(auth.provider))
    end
    redirect_to localized_edit_registration_path(current_user)
  end

  def authenticate_or_register(auth)
    user = User.from_omniauth(auth)
    if user&.persisted?
      sign_in(user, event: :authentication)
      if user.saved_change_to_id?
        # 新規ユーザ
        redirect_to localized_edit_registration_path(user)
      else
        redirect_to root_path(locale: oauth_locale_for(user))
      end
      flash[:notice] = I18n.t("devise.omniauth_callbacks.provider.success", provider: OmniAuth::Utils.camelize(auth.provider)) if is_navigational_format?
    else
      session["devise.github_data"] = auth.except(:extra)
      redirect_to localized_new_registration_path, alert: I18n.t("devise.omniauth_callbacks.failure", kind: OmniAuth::Utils.camelize(auth.provider))
    end
  end

  def localized_edit_registration_path(user)
    locale = oauth_locale_for(user)
    edit_user_registration_path(locale: locale)
  end

  def localized_new_registration_path
    locale = oauth_locale_for(nil)
    new_user_registration_path(locale: locale)
  end

  def oauth_locale_for(user)
    OAuthLocaleService.new(self, user).determine_oauth_locale[:locale] ||
      LocaleService.new(self, user).determine_effective_locale
  end

  def effective_locale_for_failure
    LocaleService.new(self, current_user).determine_effective_locale
  end

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

  def restore_oauth_locale_from_session
    return nil unless session[:oauth_locale_timestamp]
    if Time.current.to_i - session[:oauth_locale_timestamp] < OAUTH_LOCALE_SESSION_TTL
      locale = session.delete(:oauth_locale)
      session.delete(:oauth_locale_timestamp)
      return { locale: locale } if LocaleValidator.valid_locale?(locale)
    else
      session.delete(:oauth_locale)
      session.delete(:oauth_locale_timestamp)
    end
    nil
  end

  # --- サービスクラスは現状維持 ---
  class OAuthLocaleService < LocaleService
    def initialize(oauth_controller, current_user = nil)
      super(oauth_controller, current_user)
      @oauth_controller = oauth_controller
    end

    def determine_oauth_locale
      result = extract_from_omniauth_params
      return result if result[:locale]
      result = extract_from_session
      return result if result[:locale]
      if current_user
        result = extract_from_user(current_user)
        return result if result[:locale]
      end
      result = extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE'])
      return result if result[:locale]
      { locale: I18n.default_locale.to_s, source: LocaleService::SOURCE_DEFAULT }
    end

    private

    def extract_from_omniauth_params
      omniauth_params = request.env["omniauth.params"] || {}
      oauth_locale = omniauth_params["lang"] || omniauth_params["locale"]
      if oauth_locale.present? && LocaleValidator.valid_locale?(oauth_locale)
        { locale: oauth_locale, source: LocaleService::SOURCE_OMNIAUTH_PARAMS }
      else
        { locale: nil, source: nil }
      end
    end

    def extract_from_session
      session_data = @oauth_controller.send(:restore_oauth_locale_from_session)
      return { locale: nil, source: nil } unless session_data
      locale = session_data.is_a?(Hash) ? session_data[:locale] : session_data
      if locale
        { locale: locale, source: LocaleService::SOURCE_SESSION }
      else
        { locale: nil, source: nil }
      end
    end
  end
end
