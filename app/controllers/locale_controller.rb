require 'ostruct'

class LocaleController < ApplicationController
  def update
    locale = params[:locale].to_s
    if LocaleValidator.valid_locale?(locale)
      # redirect_toパラメータがある場合はそれを使用し、なければルートパスを使用
      redirect_to_path = if params[:redirect_to].present? && params[:redirect_to].start_with?('/')
                          params[:redirect_to]
                        else
                          '/'
                        end
      
      # LocaleHelperを使用してパスベースロケールURLを生成
      mock_request = OpenStruct.new(path: redirect_to_path, query_string: '')
      redirect_path = LocaleHelper.current_path_with_locale(mock_request, locale)
      redirect_to redirect_path
    else
      redirect_back(fallback_location: root_path, alert: "Unsupported locale")
    end
  end
end
