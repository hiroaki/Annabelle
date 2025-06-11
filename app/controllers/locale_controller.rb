require 'ostruct'

class LocaleController < ApplicationController
  def update
    locale = params[:locale].to_s
    if LocaleValidator.valid_locale?(locale)
      # refererまたは現在のパスを使用してリダイレクト先を決定
      if request.referer
        referer_uri = URI(request.referer)
        referer_path = referer_uri.path
        referer_query = referer_uri.query || ''
      else
        referer_path = '/'
        referer_query = ''
      end
      
      mock_request = OpenStruct.new(path: referer_path, query_string: referer_query)
      redirect_path = LocaleHelper.current_path_with_locale(mock_request, locale)
      redirect_to redirect_path
    else
      redirect_back(fallback_location: root_path, alert: "Unsupported locale")
    end
  end
end
