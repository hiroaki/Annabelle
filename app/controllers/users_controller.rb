class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  # user GET /users/:id(.:format)
  def show
  end

  # edit_user GET /users/:id/edit(.:format)
  def edit
  end

  # PATCH /users/:id(.:format)
  # PUT /users/:id(.:format)
  def update
    if @user.update(user_params_for_profile)
      # preferred_languageが実際に変更されたかチェック
      language_changed = @user.saved_change_to_preferred_language?
      
      # フォームで選択された言語を取得
      form_selected_language = params[:user][:preferred_language]
      
      # 有効なロケールを決定（フォーム選択に基づく）
      effective_locale = determine_effective_locale(form_selected_language)
      
      # 現在のURLロケールと異なる場合、または言語が変更された場合はリダイレクト
      current_url_locale = params[:locale] || I18n.default_locale.to_s
      
      # flashメッセージも選択された言語で表示
      I18n.with_locale(effective_locale) { flash[:notice] = I18n.t('users.update.success') }
      
      # 言語設定が変更された場合は、適切なロケールでリダイレクト
      if effective_locale != current_url_locale || language_changed
        target_url = build_redirect_url(effective_locale)
        redirect_to target_url
      else
        # 言語設定が変更されていない場合は編集画面に戻る
        redirect_to edit_profile_path
      end
    else
      render :edit
    end
  end

  # two_factor_authentication_user GET /users/:id/two_factor_authentication(.:format)
  def two_factor_authentication
  end

  private

  def set_user
    @user = current_user
  end

  def user_params_for_profile
    params.require(:user).permit(:username, :preferred_language)
  end

  def determine_effective_locale(new_preferred_language)
    if new_preferred_language.present?
      # フォームで具体的な言語が選択された場合
      new_preferred_language
    else
      # 未選択（""）の場合はブラウザ設定に従う
      result = locale_service.extract_from_header(request.env['HTTP_ACCEPT_LANGUAGE'])
      result[:locale] || I18n.default_locale.to_s
    end
  end

  def build_redirect_url(effective_locale)
    edit_profile_path(locale: effective_locale)
  end
end
