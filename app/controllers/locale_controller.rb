class LocaleController < ApplicationController
  include LocaleHelper

  def update
    locale = params[:locale].to_s
    if LocaleValidator.valid_locale?(locale)
      # redirect_toパラメータがある場合はそれを使用し、なければルートパスを使用
      redirect_to_path = if params[:redirect_to].present? && params[:redirect_to].start_with?('/')
                          params[:redirect_to]
                        else
                          '/'
                        end
      
      # インスタンスメソッドで呼び出し
      redirect_path = current_path_with_locale(redirect_to_path, locale)
      redirect_to redirect_path
    else
      redirect_back(fallback_location: root_path, alert: "Unsupported locale")
    end
  end
end
