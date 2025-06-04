# Language switching controller
class LocaleController < ApplicationController
  def update
    locale = params[:locale].to_s
    if I18n.available_locales.map(&:to_s).include?(locale)
      session[:locale] = locale

      # ログインユーザーの場合は設定を保存
      if user_signed_in?
        current_user.update(preferred_language: locale)
      end

      redirect_back(fallback_location: root_path)
    else
      redirect_back(fallback_location: root_path, alert: "Unsupported locale")
    end
  end
end
