# Language switching controller
class LocaleController < ApplicationController
  def update
    locale = params[:locale].to_s
    if I18n.available_locales.map(&:to_s).include?(locale)
      # ユーザ設定の言語とは別に、一時的に別の表示言語に変えることができるように、
      # session にも保存します。読み取りの優先順を確認してください。
      set_locale_to_cookie(locale)
      set_locale_to_session(locale)
      redirect_back(fallback_location: root_path)
    else
      redirect_back(fallback_location: root_path, alert: "Unsupported locale")
    end
  end
end
