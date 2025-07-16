class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  # dashboard GET /:locale/dashboard(.:format)
  def show
  end

  # edit_profile GET /:locale/profile/edit(.:format)
  def edit
  end

  # update_profile PATCH /:locale/profile(.:format)
  def update
    @language_switcher_path = edit_profile_path

    if @user.update(user_params_for_profile)
      language_changed = @user.saved_change_to_preferred_language?
      form_selected_language = params[:user][:preferred_language]
      effective_locale = determine_effective_locale(form_selected_language)
      current_url_locale = params[:locale] || I18n.default_locale.to_s

      # Show flash message in the selected language
      I18n.with_locale(effective_locale) { flash[:notice] = I18n.t('users.update.success') }

      # Redirect if locale or language setting changed
      if effective_locale != current_url_locale || language_changed
        target_url = build_redirect_url(effective_locale)
        redirect_to target_url
      else
        redirect_to edit_profile_path
      end
    else
      render :edit
    end
  end

  # two_factor_authentication GET /:locale/profile/two_factor_authentication(.:format)
  def two_factor_authentication
  end

  private

  def set_user
    @user = current_user
  end

  def user_params_for_profile
    params.require(:user).permit(:username, :preferred_language)
  end

  # Returns the effective locale based on form selection or browser settings
  def determine_effective_locale(new_preferred_language)
    if new_preferred_language.present?
      new_preferred_language
    else
      header = request.env['HTTP_ACCEPT_LANGUAGE']
      result = nil
      if header
        parser = HttpAcceptLanguage::Parser.new(header)
        available = LocaleConfiguration.available_locales.map(&:to_s)
        preferred = parser.preferred_language_from(available)
        result = preferred if LocaleUtils.valid_locale?(preferred)
      end
      result || I18n.default_locale.to_s
    end
  end

  def build_redirect_url(effective_locale)
    edit_profile_path(locale: effective_locale)
  end
end
