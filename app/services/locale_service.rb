# ロケール関連の処理を集約するサービスモジュール
module LocaleService
  # クラスメソッドとしてロケール決定のみを担当
  def self.determine_locale(params, request, user)
    # 1. params[:locale]
    return params[:locale] if valid_locale?(params[:locale])
    # 2. user.preferred_language
    return user.preferred_language if user&.preferred_language.present? && valid_locale?(user.preferred_language)
    # 3. Accept-Language
    header = request.env['HTTP_ACCEPT_LANGUAGE']
    if header
      parser = HttpAcceptLanguage::Parser.new(header)
      available = LocaleConfiguration.available_locales.map(&:to_s)
      preferred = parser.preferred_language_from(available)
      return preferred if valid_locale?(preferred)
    end
    # 4. デフォルト
    I18n.default_locale.to_s
  end

  def self.valid_locale?(locale)
    LocaleValidator.valid_locale?(locale)
  end
end
