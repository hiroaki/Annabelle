class MessagesChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    logger.info("MessagesChannel#subscribed: subscribed")

    stream_from 'general_message_board'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    logger.info("MessagesChannel#unsubscribed: unsubscribed")
  end
end
