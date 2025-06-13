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
end
