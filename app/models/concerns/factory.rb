module Factory
  def create_message!(params)
    message = Message.create!(params)
    MessageBroadcastJob.perform_later(message.id)
  end

  def destroy_message!(id)
    message = Message.find(id)
    message.destroy!
    MessageBroadcastJob.perform_later(message.id)
  end
end
