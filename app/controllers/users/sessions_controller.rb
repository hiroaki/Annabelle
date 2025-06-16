class Users::SessionsController < Devise::SessionsController
  include Users::AuthenticateWithOtpTwoFactor

  prepend_before_action :authenticate_with_otp_two_factor,
    if: -> { action_name == 'create' && otp_two_factor_enabled? }

  protect_from_forgery with: :exception, prepend: true, except: :destroy
  before_action :store_language_for_logout, only: [:destroy]  # ログアウト前に言語設定を保存

  # (override)
  # デフォルトの root_path はログインが必須なため、ログイン画面へリダイレクトします。
  # 結果的に同じ画面へすすむのですが、リダイレクトが挟まると flash が消えてしまうため、
  # ここで直接ログイン画面を指定するようにしています。
  # また、ログアウト前の言語設定を可能な限り維持します。
  def after_sign_out_path_for(resource_or_scope)
    locale = determine_logout_locale
    
    if locale && locale != I18n.default_locale.to_s
      new_session_path(resource_or_scope, locale: locale)
    else
      new_session_path(resource_or_scope)
    end
  end

  private

  def store_language_for_logout
    # 現在の言語設定を一時的に保存
    # langパラメータを削除し、localeパラメータを使用
    # 1. URLパラメータのlocale（明示的ロケール必須化により常に存在）
    # 2. 現在のI18n.locale
    # 3. ユーザーの設定言語
    if params[:locale].present? && LocaleValidator.valid_locale?(params[:locale])
      session[:logout_locale] = params[:locale]
    elsif I18n.locale && I18n.locale != I18n.default_locale
      session[:logout_locale] = I18n.locale.to_s
    elsif user_signed_in? && current_user.preferred_language.present?
      session[:logout_locale] = current_user.preferred_language
    end
  end

  def determine_logout_locale
    # ログアウト後に使用する言語を決定
    logout_locale = session.delete(:logout_locale)
    
    if LocaleValidator.valid_locale?(logout_locale)
      logout_locale
    else
      # デフォルトロケールまたはブラウザ設定から決定
      nil
    end
  end
end
