import consumer from "channels/consumer"

consumer.subscriptions.create("MessagesChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    console.log("MessagesChannel: connected")
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
    console.log("MessagesChannel: disconnected")
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log("MessagesChannel: received", data)

    const messages = document.getElementById('messages');
    messages.insertAdjacentHTML('afterbegin', data['rendered_message']);
  }
});
