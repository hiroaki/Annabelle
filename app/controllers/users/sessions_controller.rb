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
end
