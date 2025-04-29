class MessagesController < ApplicationController
  include Factory

  before_action :authenticate_user!

  def index
    @messages = Message.order(created_at: :desc).page(params[:page])
  end

  def create
    create_message!(message_params.merge(user: current_user_or_admin))
  rescue => ex
    flash.now.alert = "#{ex.message}"
  end

  def destroy
    destroy_message_if_owner!(params[:id], current_user)
  rescue MessageNotOwnedError
    flash.now.alert = "You cannot delete this message because it does not belong to you."
  rescue => ex
    flash.now.alert = "#{ex.message}"
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

  public
end
