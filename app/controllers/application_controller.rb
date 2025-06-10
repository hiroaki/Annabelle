class ApplicationController < ActionController::Base
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :conditional_auto_login

  # サインイン後のリダイレクト先を制御しています。
  # これは通常、デフォルトの root_path にリダイレクトしますが、
  # session[:just_signed_up] に値がセットされている場合は、プロフィール編集画面（edit）へ遷移させます。
  #
  # そのフローはセッションが新規登録ユーザーのものであることを想定しており、
  # ランダム生成された初期値のユーザー名などを編集してもらうための導線を意図しています。
  def after_sign_in_path_for(resource)
    if session.delete(:just_signed_up)
      edit_user_registration_path
    else
      super
    end
  end

  protected

  def set_locale_to_cookie(locale)
    cookies.permanent[:locale] = locale if valid_locale?(locale)
  end

  def set_locale_to_session(locale)
    session[:locale] = locale if valid_locale?(locale)
  end

  # TODO: FIXME:
  #   現在の実装は session や cookie を用いています。
  #   ロケールを URL の一部として扱うようにルーティングから見直してください。
  #
  # 『Railsガイド』から引用：
  # https://railsguides.jp/i18n.html
  # 2.2.5 セッションやcookieに含まれるロケールの保存について
  #   開発者は、選択したロケールをセッションやcookieに保存したくなる誘惑にかられるかもしれません。
  #   しかしこれは行ってはいけません。
  #   ロケールは透過的にすべきであり、かつURLの一部に含めるべきです。
  def set_locale(locale = nil)
    # FORM からのパラメータで、言語未設定の場合は locale が空文字になります。
    I18n.locale = locale.presence || extract_locale || I18n.default_locale
  end

  private

  # ユーザ設定の言語とは別に、一時的に別の表示言語に変えることができるように、
  # session にも保存しています。
  # cookie はログインしていない状況のために使います。
  def extract_locale
    locale = locale_from_params
    Rails.logger.debug "locale_from_params: #{locale}"
    return locale if locale

    locale = locale_from_session
    Rails.logger.debug "locale_from_session: #{locale}"
    return locale if locale

    locale = locale_from_user
    Rails.logger.debug "locale_from_user: #{locale}"
    return locale if locale

    locale = locale_from_cookie
    Rails.logger.debug "locale_from_cookie: #{locale}"
    return locale if locale

    locale = locale_from_header
    Rails.logger.debug "locale_from_header: #{locale}"
    locale
  end

  def locale_from_params
    if params[:locale].present? && valid_locale?(params[:locale])
      params[:locale]
    end
  end

  def locale_from_user
    return unless user_signed_in?
    current_user.preferred_language unless current_user.preferred_language.empty?
  end

  def locale_from_session
    locale = session[:locale]
    locale if valid_locale?(locale)
  end

  def locale_from_cookie
    locale = cookies[:locale]
    locale if valid_locale?(locale)
  end

  # 『Railsガイド』より引用：
  # 実際には、この信頼性を実現するのにより堅固なコードが必要です。
  # Iain Hackerのhttp_accept_languageライブラリやRyan TomaykoのlocaleRackミドルウェアが
  # この問題へのソリューションを提供しています。
  def locale_from_header
    return unless request.env['HTTP_ACCEPT_LANGUAGE']
    locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    locale if valid_locale?(locale)
  end

  def valid_locale?(locale)
    LocaleValidator.valid_locale?(locale)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :preferred_language])
  end

  # My experimental feature
  def conditional_auto_login
    return unless Rails.configuration.x.auto_login.enabled
    return if user_signed_in?

    email = Rails.configuration.x.auto_login.email.presence
    user = email ? User.find_by!(email: email) : User.admin_user
    if !user.present? || !user.active_for_authentication?
      # 実行時までここのエラーに気が付けないですが、
      # このケースはいわゆる「一人で使うためのモード」の中であるため許容します。
      raise "conditional_auto_login failed"
    end

    # ログイン不可な user をセットしてしまうと無限ループに陥るので注意。
    sign_in(:user, user)
  end
end
