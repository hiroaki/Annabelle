# Language switching controller
class LocaleController < ApplicationController
  def update
    locale = params[:locale].to_s
    if I18n.available_locales.map(&:to_s).include?(locale)
      set_locale_to_cookie(locale)
      redirect_back(fallback_location: root_path)
    else
      redirect_back(fallback_location: root_path, alert: "Unsupported locale")
    end
  end
end
