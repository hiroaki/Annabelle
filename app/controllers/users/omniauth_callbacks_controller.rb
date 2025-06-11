class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :github
  
  # OAuthパラメータからロケールを先に保存
  before_action :store_locale_for_redirect

  def github
    auth = request.env["omniauth.auth"]

    if user_signed_in?
      if current_user.linked_with?(auth.provider) && current_user.provider_uid(auth.provider) != auth.uid
        flash[:alert] = I18n.t("devise.omniauth_callbacks.provider.already_linked", provider: OmniAuth::Utils.camelize(auth.provider))
        redirect_to localized_edit_registration_path and return
      else
        current_user.link_with(auth.provider, auth.uid)
        flash[:notice] = I18n.t("devise.omniauth_callbacks.provider.success", provider: OmniAuth::Utils.camelize(auth.provider))
        redirect_to localized_edit_registration_path
      end
    else
      @user = User.from_omniauth(auth)

      if @user&.persisted?
        # 新規ユーザーかどうかをインスタンス変数で管理（セッション不使用）
        @is_new_user = @user.saved_change_to_id?

        sign_in(@user, event: :authentication)
        # 言語を考慮したリダイレクト先を明示的に指定
        redirect_to determine_oauth_redirect_path
        flash[:notice] = I18n.t("devise.omniauth_callbacks.provider.success", provider: OmniAuth::Utils.camelize(auth.provider)) if is_navigational_format?
      else
        session["devise.github_data"] = auth.except(:extra)
        redirect_to localized_new_registration_path, alert: I18n.t("devise.omniauth_callbacks.failure", provider: OmniAuth::Utils.camelize(auth.provider))
      end
    end
  end

  def failure
    provider = request.env["omniauth.error.strategy"]&.name&.to_s&.humanize || I18n.t("devise.omniauth_callbacks.unknown_provider")
    redirect_to localized_new_session_path, alert: I18n.t("devise.omniauth_callbacks.failure", provider: provider)
  end

  private

  def store_locale_for_redirect
    # OAuthプロセス開始時の言語設定を保持
    Rails.logger.debug "OAuth: All params: #{params.inspect}"
    Rails.logger.debug "OAuth: Omniauth params: #{request.env['omniauth.params']}"
    Rails.logger.debug "OAuth: Omniauth origin: #{request.env['omniauth.origin']}"
    
    # OAuth認証では request.env["omniauth.params"] から取得
    omniauth_params = request.env["omniauth.params"] || {}
    locale_param = params[:lang] || params[:locale] || omniauth_params["lang"] || omniauth_params["locale"]
    
    # omniauth.originからロケールを抽出することも試す
    if locale_param.blank? && request.env['omniauth.origin'].present?
      origin_uri = URI.parse(request.env['omniauth.origin'])
      if origin_uri.path =~ /^\/([a-z]{2})\//
        locale_param = $1
      end
      origin_params = Rack::Utils.parse_query(origin_uri.query) if origin_uri.query
      locale_param ||= origin_params&.dig('lang')
    end
    
    if locale_param.present? && LocaleValidator.valid_locale?(locale_param)
      @oauth_locale = locale_param
      Rails.logger.debug "OAuth: Stored locale parameter '#{locale_param}' in instance variable"
    else
      Rails.logger.debug "OAuth: No valid locale parameter found. params[:lang] = '#{params[:lang]}', params[:locale] = '#{params[:locale]}', omniauth lang='#{omniauth_params["lang"]}', omniauth locale='#{omniauth_params["locale"]}'"
      # 現在のロケールがデフォルトでない場合は保存
      if I18n.locale != I18n.default_locale
        @oauth_locale = I18n.locale.to_s
        Rails.logger.debug "OAuth: Stored current I18n.locale '#{I18n.locale}' in instance variable"
      end
    end
    
    Rails.logger.debug "OAuth: Instance oauth_locale: #{@oauth_locale}"
  end

  def stored_locale
    # セッションの代わりにインスタンス変数を使用
    locale = @oauth_locale if LocaleValidator.valid_locale?(@oauth_locale)
    Rails.logger.debug "OAuth: Retrieved stored locale '#{locale}' from instance variable"
    locale
  end

  def localized_edit_registration_path
    locale = stored_locale || I18n.locale.to_s
    Rails.logger.debug "OAuth: Using locale '#{locale}' for edit registration path (stored: #{stored_locale}, I18n: #{I18n.locale})"
    if locale == I18n.default_locale.to_s
      edit_user_registration_path
    else
      edit_user_registration_path(locale: locale)
    end
  end

  def localized_new_registration_path
    locale = stored_locale || I18n.locale.to_s
    if locale == I18n.default_locale.to_s
      new_user_registration_path
    else
      new_user_registration_path(locale: locale)
    end
  end

  def localized_new_session_path
    locale = stored_locale || I18n.locale.to_s
    if locale == I18n.default_locale.to_s
      new_user_session_path
    else
      new_user_session_path(locale: locale)
    end
  end

  def determine_oauth_redirect_path
    if @is_new_user
      # 新規ユーザーはアカウント設定ページへ
      localized_edit_registration_path
    else
      # 既存ユーザーは適切な言語のルートページへ
      locale = stored_locale || I18n.locale.to_s
      if locale == I18n.default_locale.to_s
        root_path
      else
        root_path(locale: locale)
      end
    end
  end
end
