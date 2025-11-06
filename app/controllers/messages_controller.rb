class MessagesController < ApplicationController
  include Factory

  before_action :authenticate_user!
  before_action :require_confirmed_user_for_non_safe_requests

  def index
    set_messages
  end

  def create
    create_message!(message_params.merge(user: current_user))
  rescue => ex
    flash.now.alert = I18n.t('messages.errors.generic', error_message: ex.message)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update('flash-storage', partial: 'shared/flash_storage') }
      format.html { render :index, status: :unprocessable_content }
    end
  end

  def destroy
    destroy_message_if_owner!(params[:id], current_user)
  rescue MessageNotOwnedError
    flash.now.alert = I18n.t('messages.errors.not_owned')
    set_messages
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.update('flash-storage', partial: 'shared/flash_storage')
      }
      format.html { render :index, status: :unprocessable_content }
    end
  rescue => ex
    flash.now.alert = I18n.t('messages.errors.generic', error_message: ex.message)
    set_messages
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update('flash-storage', partial: 'shared/flash_storage') }
      format.html { render :index, status: :unprocessable_content }
    end
  end

  private

    def message_params
      params.permit(:content, attachements: [])
    end

    def require_confirmed_user_for_non_safe_requests
      return if request.get? || request.head?
      return if current_user.confirmed?

      render plain: 'Email confirmation required', status: :forbidden
    end

    def set_messages
      @messages = Message.order(created_at: :desc).page(params[:page])
    end

  public
end
