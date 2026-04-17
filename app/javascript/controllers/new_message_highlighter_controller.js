// This Stimulus controller removes the highlight from a new message when the user moves the pointer over it or focuses it.
// ユーザーが新着メッセージ上でマウスを動かすかフォーカスすると、ハイライトを解除するStimulusコントローラです。
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.getAttribute('data-new-message') !== 'true') return

    this.boundHandleUserActivity = this.handleUserActivity.bind(this)
    this.element.addEventListener('mousemove', this.boundHandleUserActivity)
    this.element.addEventListener('focusin', this.boundHandleUserActivity)
  }

  disconnect() {
    if (!this.boundHandleUserActivity) return

    this.element.removeEventListener('mousemove', this.boundHandleUserActivity)
    this.element.removeEventListener('focusin', this.boundHandleUserActivity)
  }

  handleUserActivity() {
    if (this.element.getAttribute('data-new-message') === 'true') {
      this.element.removeAttribute('data-new-message')
    }

    this.element.removeEventListener('mousemove', this.boundHandleUserActivity)
    this.element.removeEventListener('focusin', this.boundHandleUserActivity)
  }
}
