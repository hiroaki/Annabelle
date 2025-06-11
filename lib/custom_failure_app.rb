class CustomFailureApp < Devise::FailureApp
  def redirect_url
    # langパラメータを取得
    lang_param = request.params[:lang]
    
    # ベースのリダイレクトURLを取得
    url = super
    
    # langパラメータが有効な場合は追加
    if lang_param.present? && valid_locale?(lang_param)
      separator = url.include?('?') ? '&' : '?'
      url += "#{separator}lang=#{lang_param}"
    end
    
    url
  end

  private

  def valid_locale?(locale)
    LocaleValidator.valid_locale?(locale)
  end
end