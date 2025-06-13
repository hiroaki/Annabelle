require 'ostruct'

class LocaleController < ApplicationController
  def update
    locale = params[:locale].to_s
    if LocaleValidator.valid_locale?(locale)
      # パスベースロケール戦略に変更
      # refererから現在のパスを取得し、新しいロケール付きパスにリダイレクト
      if request.referer
        referer_uri = URI(request.referer)
        referer_path = referer_uri.path
      else
        referer_path = '/'
      end
      
      # LocaleHelperを使用してパスベースロケールURLを生成
      mock_request = OpenStruct.new(path: referer_path, query_string: '')
      redirect_path = LocaleHelper.current_path_with_locale(mock_request, locale)
      redirect_to redirect_path
    else
      redirect_back(fallback_location: root_path, alert: "Unsupported locale")
    end
  end
end
