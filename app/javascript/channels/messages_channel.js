import consumer from "channels/consumer"
import { appendMessageToStorage, renderFlashMessages, clearFlashMessages } from "flash_unified/all"

consumer.subscriptions.create("MessagesChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    console.log("MessagesChannel: connected")
    this.boundDocumentClick = this.handleDocumentClick.bind(this)
    this.boundSyncMessagesUi = this.syncMessagesUi.bind(this)

    document.addEventListener('click', this.boundDocumentClick)
    document.addEventListener('turbo:load', this.boundSyncMessagesUi)
    document.addEventListener('turbo:render', this.boundSyncMessagesUi)

    this.syncMessagesUi()
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
    console.log("MessagesChannel: disconnected");
    this.messagesContainer()?.setAttribute('data-channel-connected', 'false')
    document.removeEventListener('click', this.boundDocumentClick)
    document.removeEventListener('turbo:load', this.boundSyncMessagesUi)
    document.removeEventListener('turbo:render', this.boundSyncMessagesUi)

    const flashMessage = this.disconnectedMessage();
    clearFlashMessages(flashMessage);
    appendMessageToStorage(flashMessage, 'warning');
    renderFlashMessages();
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log("MessagesChannel: received", data)

    const messages = document.getElementById('messages');

    const notificationTargets = document.querySelectorAll('[data-messages-channel="notification"]');
    const page = document.querySelector('[data-current-page-number]')?.dataset?.currentPageNumber; // or undefined

    if (data['created']) {
      if (!messages) {
        notificationTargets.forEach((nt) => nt.classList.remove('hidden'));
        return;
      }

      if (!page || page == '1') {
        if (this.createdByCurrentUser(messages, data)) {
          // Own posts are shown immediately and intentionally keep the same
          // temporary highlight as other newly inserted messages.
          this.insertVisibleMessage(data['rendered_message'], { highlight: true });
        } else {
          this.insertPendingMessage(data['rendered_message'], { highlight: true })
          this.updatePendingMessagesNotice();
        }
      } else {
        notificationTargets.forEach((nt) => nt.classList.remove('hidden'));
      }
    }
    else if (data['destroyed']) {
      if (!messages) return;

      const destroyedMessageId = String(data['destroyed'])
      messages.querySelectorAll(`[data-message-id="${destroyedMessageId}"]`).forEach((elem) => {
        if (elem.dataset['pendingMessage'] === 'true') {
          elem.remove()
          return
        }

        this.convertToDeletedMessage(elem)
      })
      this.updatePendingMessagesNotice()
    }
  },

  revealPendingMessages() {
    if (!this.messagesContainer()) return;

    const pending = this.pendingMessageElements()
    if (pending.length === 0) return;

    pending.forEach((message) => {
      message.classList.remove('hidden')
      message.removeAttribute('aria-hidden')
      message.removeAttribute('data-pending-message')
    })

    const lastRevealed = pending[pending.length - 1]
    if (lastRevealed) {
      lastRevealed.insertAdjacentElement('afterend', this.buildSeparatorElement())
    }

    this.updatePendingMessagesNotice()
  },

  handleDocumentClick(event) {
    const revealButton = event.target.closest('[data-role="new-messages-reveal"]')
    if (!revealButton || revealButton !== this.pendingNoticeButton()) return

    this.revealPendingMessages()
  },

  syncMessagesUi() {
    this.messagesContainer()?.setAttribute('data-channel-connected', 'true')
    this.updatePendingMessagesNotice()
  },

  insertPendingMessage(renderedMessage, { highlight = true } = {}) {
    const element = this.buildMessageElement(renderedMessage, { highlight })
    if (!element) return

    element.setAttribute('data-pending-message', 'true')
    element.setAttribute('aria-hidden', 'true')
    element.classList.add('hidden')

    const notice = this.pendingMessagesNotice()
    if (notice) {
      notice.insertAdjacentElement('afterend', element)
      return
    }

    this.messagesContainer()?.insertAdjacentElement('afterbegin', element)
  },

  insertVisibleMessage(renderedMessage, { highlight = true } = {}) {
    const element = this.buildMessageElement(renderedMessage, { highlight })
    if (!element) return

    const notice = this.pendingMessagesNotice()
    if (notice) {
      notice.insertAdjacentElement('afterend', element)
      return
    }

    this.messagesContainer()?.insertAdjacentElement('afterbegin', element)
  },

  updatePendingMessagesNotice() {
    const notice = this.pendingMessagesNotice()
    const button = this.pendingNoticeButton()
    if (!notice || !button) return;

    const count = this.pendingMessageElements().length

    if (count === 0) {
      notice.dataset.pendingVisible = 'false'
      notice.classList.add('hidden')
      button.classList.add('hidden')
      button.textContent = ''
      return
    }

    notice.dataset.pendingVisible = 'true'
    button.textContent = this.pendingMessagesText(count)
    button.classList.remove('hidden')
    notice.classList.remove('hidden')
  },

  createdByCurrentUser(messages, data) {
    const currentUserId = messages.dataset['currentUserId']
    const senderUserId = data['sender_user_id'] || this.extractOwnerId(data['rendered_message'])
    return currentUserId && senderUserId && String(currentUserId) === String(senderUserId)
  },

  extractOwnerId(renderedMessage) {
    if (!renderedMessage) return null

    const template = document.createElement('template')
    template.innerHTML = renderedMessage.trim()
    return template.content.firstElementChild?.dataset?.ownerId || null
  },

  messagesContainer() {
    return document.getElementById('messages')
  },

  buildMessageElement(renderedMessage, { highlight = true } = {}) {
    if (!renderedMessage) return null

    const template = document.createElement('template')
    template.innerHTML = renderedMessage.trim()
    const element = template.content.firstElementChild
    if (element && highlight) element.setAttribute('data-new-message', 'true')
    return element
  },

  pendingMessagesNotice() {
    return document.getElementById('new-messages-notice')
  },

  pendingNoticeButton() {
    return this.pendingMessagesNotice()?.querySelector('[data-role="new-messages-reveal"]') || null
  },

  pendingMessageElements() {
    return Array.from(this.messagesContainer()?.querySelectorAll('[data-pending-message="true"]') || [])
  },

  convertToDeletedMessage(messageElement) {
    if (!messageElement || messageElement.dataset['deletedMessage'] === 'true') return

    messageElement.dataset.deletedMessage = 'true'
    messageElement.removeAttribute('data-new-message')
    messageElement.classList.remove('bg-white')
    messageElement.classList.add('bg-gray-100')

    const deleteLink = messageElement.querySelector('[data-message-ownership-target="owner"]')
    if (deleteLink) deleteLink.remove()

    const body = messageElement.querySelector('[data-message-body="true"]')
    if (body) {
      body.textContent = this.deletedMessageText()
      body.classList.remove('text-nowrap')
      body.classList.add('text-gray-500', 'italic')
    }

    const attachments = messageElement.querySelector('[data-message-attachments="true"]')
    if (attachments) attachments.innerHTML = ''
  },

  deletedMessageText() {
    const fallback = 'This message was deleted.'
    return this.localeMessage('message_deleted') || fallback
  },

  buildSeparatorElement() {
    const wrapper = document.createElement('div')
    wrapper.className = 'mb-2 py-2'
    wrapper.dataset.role = 'new-messages-separator'
    wrapper.setAttribute('aria-hidden', 'true')

    const line = document.createElement('div')
    line.className = 'w-full border-t border-blue-200'
    wrapper.appendChild(line)

    return wrapper
  },

  pendingMessagesText(count) {
    const key = 'new_messages_available_count'
    const fallback = `${count} new messages — click to show`
    const template = this.localeMessage(key) || fallback
    return template.replace('%{count}', count)
  },

  localeMessage(key) {
    const localeMessage = document.querySelector(`#exported-locale-messages li[data-key="${key}"]`)
    return localeMessage ? localeMessage.textContent : null
  },

  disconnectedMessage() {
    const fallbackMessage = "Connection to the server has been lost. Please reload the page to reconnect";
    return this.localeMessage('cable_disconnected') || fallbackMessage;
  }
});
