class MessagesController < ApplicationController
  def show
    @messages = Message.all.limit(5)
  end
end
