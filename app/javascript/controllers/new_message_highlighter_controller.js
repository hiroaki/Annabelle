// This Stimulus controller removes the highlight from a new message when the user hovers or focuses it.
// ユーザーが新着メッセージにマウスを乗せるかフォーカスすると、ハイライトを解除するStimulusコントローラです。
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundHandleUserActivity = this.handleUserActivity.bind(this)
    this.element.addEventListener('mouseenter', this.boundHandleUserActivity)
    this.element.addEventListener('focusin', this.boundHandleUserActivity)
  }

  disconnect() {
    this.element.removeEventListener('mouseenter', this.boundHandleUserActivity)
    this.element.removeEventListener('focusin', this.boundHandleUserActivity)
  }

  handleUserActivity() {
    if (this.element.getAttribute('data-new-message') === 'true') {
      this.element.removeAttribute('data-new-message')
      this.element.removeEventListener('mouseenter', this.boundHandleUserActivity)
      this.element.removeEventListener('focusin', this.boundHandleUserActivity)
    }
  }
}
