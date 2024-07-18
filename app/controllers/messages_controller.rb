class MessagesController < ApplicationController
  include Factory

  def index
    @messages = Message.all.limit(25).order(created_at: :desc)
  end

  def create
    create_message!(message_params)
    head :no_content
  end

  def destroy
    destroy_message!(params[:id])
    head :no_content
  end

  private

    def message_params
        params.permit(:content, attachements: [])
    end
end
