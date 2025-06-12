class LocaleRedirectController < ApplicationController
  # ロケール決定前のアクションのため、set_localeをスキップ
  skip_before_action :set_locale

  # ルートパス (/) へのアクセス時に適切なロケール付きURLにリダイレクト
  def root
    # LocaleServiceを使用してロケールを決定
    locale_service = LocaleService.new(self)
    effective_locale = locale_service.determine_effective_locale
    
    # リダイレクト前にI18n.localeを設定（flashメッセージの言語統一のため）
    I18n.locale = effective_locale

    # クエリパラメータを保持してリダイレクト
    redirect_params = { locale: effective_locale }
    redirect_params.merge!(request.query_parameters) if request.query_parameters.present?

    # 決定されたロケール付きのルートパスにリダイレクト
    redirect_to root_path(redirect_params), status: :moved_permanently
  end
end
