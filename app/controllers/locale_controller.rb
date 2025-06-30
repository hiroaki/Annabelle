class LocaleController < ApplicationController
  include LocaleHelper

  skip_before_action :set_locale, only: [:root]

  # ルートパス (/) へのアクセス時に適切なロケール付きURLにリダイレクト
  def root
    effective_locale = LocaleUtils.determine_locale(params, request, current_user)
    I18n.locale = effective_locale
    redirect_params = { locale: effective_locale }
    redirect_params.merge!(request.query_parameters) if request.query_parameters.present?
    redirect_to root_path(redirect_params), status: :moved_permanently
  end

  # locale GET /locale/:locale(.:format)
  def update
    # 変更先のロケール
    locale = params[:locale].to_s

    unless LocaleValidator.valid_locale?(locale)
      redirect_back(fallback_location: root_path, alert: I18n.t('errors.locale.unsupported_locale'))
    else
      # リダイレクト先のパス
      # 基本的にはリクエスト元と同じで、パラメータ不足の場合はルート
      redirect_to_path = root_path
      if params[:redirect_to].present? && params[:redirect_to].start_with?('/')
        redirect_to_path = params[:redirect_to]
      end

      # リダイレクト先の /:locale を "変更先のロケール" に変更してリダイレクト
      redirect_to current_path_with_locale(redirect_to_path, locale)
    end
  end
end
