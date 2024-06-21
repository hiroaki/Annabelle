module Factory
  def create_message!(params)
    MessageBroadcastJob.perform_later(Message.create!(params))
  end
end
