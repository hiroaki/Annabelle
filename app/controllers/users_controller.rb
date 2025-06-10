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
    # 現在優先されている言語設定の値を得ます
    previous_locale = extract_locale

    if @user.update(user_params_for_profile)
      if @user.preferred_language != previous_locale
        # 言語が変更された場合は画面を切り替えます
        set_locale(@user.preferred_language)
        set_locale_to_session(@user.preferred_language)
        @requires_full_page_reload_to = edit_user_path(@user)
      end

      # ログアウト後をフォローするため変更がなくとも cookie の値は更新します
      set_locale_to_cookie(@user.preferred_language)

      flash[:notice] = I18n.t('users.update.success')
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @user }
      end
    else
      respond_to do |format|
        format.turbo_stream
        format.html { render :edit }
      end
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
end
