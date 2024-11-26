class MessagesController < ApplicationController
  include Factory

  def index
    @messages = Message.order(created_at: :desc).page(params[:page])
  end

  def create
    create_message!(message_params)
  rescue => ex
    flash.now.notice = "Error: #{ex.message}"
  end

  def destroy
    destroy_message!(params[:id])
  rescue => ex
    flash.now.notice = "Error: #{ex.message}"
  end

  private

    def message_params
        params.permit(:content, attachements: [])
    end
end
