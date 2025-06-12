class ApplicationController < ActionController::Base
  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :conditional_auto_login

  # URLヘルパーに自動的にロケールパラメータを追加
  # ステップ2: フィーチャーフラグによる段階的移行対応
  def default_url_options
    if use_path_based_locale?
      # パスベース方式: /ja/users (ロケールはパスに含まれる)
      { locale: I18n.locale }
    else
      # クエリパラメータ方式: /users?lang=ja (デフォルトは空)
      {}
    end
  end

  # ログイン後のリダイレクト先を決定
  def after_sign_in_path_for(resource)
    locale_service.determine_post_login_redirect_path(resource)
  end

  protected

  # ロケールを設定し、必要に応じてリダイレクトを実行
  def set_locale(locale = nil)
    locale_service.set_locale(locale)
  end

  private

  # ロケール処理を担当するサービスオブジェクト
  def locale_service
    @locale_service ||= LocaleService.new(self)
  end

  # パスベースロケールを使用するかどうかの判定（ステップ2追加）
  def use_path_based_locale?
    Rails.application.config.respond_to?(:x) &&
      Rails.application.config.x.respond_to?(:use_path_based_locale) &&
      Rails.application.config.x.use_path_based_locale
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
