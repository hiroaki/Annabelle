class LocaleRedirectController < ApplicationController
  # ロケール決定前のアクションのため、set_localeをスキップ
  skip_before_action :set_locale

  # ルートパス (/) へのアクセス時に適切なロケール付きURLにリダイレクト
  def root
    effective_locale = LocaleService.determine_locale(params, request, current_user)
    I18n.locale = effective_locale
    redirect_params = { locale: effective_locale }
    redirect_params.merge!(request.query_parameters) if request.query_parameters.present?
    redirect_to root_path(redirect_params), status: :moved_permanently
  end
end
