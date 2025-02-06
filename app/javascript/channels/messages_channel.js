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
    const notificationTargets = document.querySelectorAll('[data-messages-channel="notification"]');
    const page = document.querySelector('[data-current-page-number]')?.dataset?.currentPageNumber; // or undefined

    if (data['created']) {
      if (page && page == '1') {
        messages.insertAdjacentHTML('afterbegin', data['rendered_message']);
      } else {
        notificationTargets.forEach((nt) => nt.classList.remove('hidden'));
      }
    }
    else if (data['destroyed']) {
      const destroyed_message_id = data['destroyed']
      messages.querySelector(`[data-message-id="${destroyed_message_id}"]`).remove();
    }
  }
});
