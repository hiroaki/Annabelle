class Users::SessionsController < Devise::SessionsController
  include Users::AuthenticateWithOtpTwoFactor

  prepend_before_action :authenticate_with_otp_two_factor,
    if: -> { action_name == 'create' && otp_two_factor_enabled? }

  protect_from_forgery with: :exception, prepend: true, except: :destroy

  # (override)
  # デフォルトの root_path はログインが必須なため、ログイン画面へリダイレクトします。
  # 結果的に同じ画面へすすむのですが、リダイレクトが挟まると flash が消えてしまうため、
  # ここで直接ログイン画面を指定するようにしています。
  def after_sign_out_path_for(resource_or_scope)
    new_session_path(resource_or_scope)
  end

  def destroy
    # ログアウト後の flash メッセージはブラウザの言語に合わせます。
    # super の中で flash メッセージが生成されます。
    current_locale = I18n.locale
    session.delete(:locale)
    browser_locale = extract_browser_locale

    if browser_locale
      I18n.with_locale(browser_locale) do
        super
      end
    else
      super
    end

    I18n.locale = current_locale
  end

  private

  def extract_browser_locale
    return unless request.env['HTTP_ACCEPT_LANGUAGE']
    locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    locale if I18n.available_locales.map(&:to_s).include?(locale.to_s)
  end
end
