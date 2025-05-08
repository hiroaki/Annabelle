class MessagesController < ApplicationController
  include Factory

  before_action :authenticate_user!
  before_action :require_confirmed_user_for_non_safe_requests  

  def index
    @messages = Message.order(created_at: :desc).page(params[:page])
  end

  def create
    create_message!(message_params.merge(user: current_user_or_admin))
  rescue => ex
    flash.now.alert = I18n.t("messages.errors.generic", error_message: ex.message)
  end

  def destroy
    destroy_message_if_owner!(params[:id], current_user)
  rescue MessageNotOwnedError
    flash.now.alert = I18n.t("messages.errors.not_owned")
  rescue => ex
    flash.now.alert = I18n.t("messages.errors.generic", error_message: ex.message)
  end

  private

    def message_params
      params.permit(:content, attachements: [])
    end

    def current_user_or_admin
      current_user || admin_user
    end

    def admin_user
      User.admin_user
    end

    def require_confirmed_user_for_non_safe_requests
      return if request.get? || request.head?
      return if current_user.confirmed?
    
      render plain: "Email confirmation required", status: :forbidden
    end

  public
end
