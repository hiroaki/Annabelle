import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["errorContainer"]

  connect() {
    // Listen for turbo:submit-end event to handle form submission results
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  handleSubmitEnd(event) {
    const { success, response } = event.detail

    // Only handle failed requests that aren't handled by Rails
    if (!success && response) {
      this.handleHttpError(response.status)
    }
  }

  handleHttpError(status) {
    let errorMessageKey = this.getErrorMessageKey(status)
    
    if (errorMessageKey) {
      this.displayError(errorMessageKey)
    }
  }

  getErrorMessageKey(status) {
    const errorMapping = {
      413: "messages.errors.proxy_413",
      502: "messages.errors.proxy_502", 
      503: "messages.errors.proxy_503",
      504: "messages.errors.proxy_504"
    }

    return errorMapping[status] || null
  }

  displayError(i18nKey) {
    // Get the localized error message
    const errorMessage = this.getLocalizedMessage(i18nKey)
    
    if (errorMessage) {
      this.showFlashMessage(errorMessage)
    }
  }

  getLocalizedMessage(i18nKey) {
    // Try to get the localized message from data attributes or fallback to hardcoded
    const locale = document.documentElement.lang || 'en'
    
    // Define fallback messages
    const fallbackMessages = {
      'en': {
        'messages.errors.proxy_413': 'The message or attached files are too large. Please reduce the file size and try again.',
        'messages.errors.proxy_502': 'The server is temporarily unavailable. Please wait a moment and try again.',
        'messages.errors.proxy_503': 'The server is temporarily unavailable. Please wait a moment and try again.',
        'messages.errors.proxy_504': 'The server response timed out. Please wait a moment and try again.',
        'messages.errors.network_error': 'A network error occurred. Please check your internet connection and try again.'
      },
      'ja': {
        'messages.errors.proxy_413': 'メッセージまたは添付ファイルのサイズが大きすぎます。ファイルサイズを小さくして再度お試しください。',
        'messages.errors.proxy_502': 'サーバーに一時的にアクセスできません。しばらく待ってから再度お試しください。',
        'messages.errors.proxy_503': 'サーバーが一時的に利用できません。しばらく待ってから再度お試しください。',
        'messages.errors.proxy_504': 'サーバーの応答がタイムアウトしました。しばらく待ってから再度お試しください。',
        'messages.errors.network_error': 'ネットワークエラーが発生しました。インターネット接続を確認して再度お試しください。'
      }
    }

    return fallbackMessages[locale]?.[i18nKey] || fallbackMessages['en'][i18nKey]
  }

  showFlashMessage(message) {
    // Find the flash message container
    const flashContainer = document.getElementById('flash-message-container')
    
    if (!flashContainer) {
      console.error('Flash message container not found')
      return
    }

    // Create a flash message element similar to the shared/_flash.html.erb partial
    const flashElement = document.createElement('div')
    flashElement.className = 'p-4 mb-4 text-sm text-red-700 bg-red-100 rounded-lg'
    flashElement.setAttribute('role', 'alert')
    // Note: Not adding dismissable controller here as it would need to be manually triggered
    // The user can refresh or submit again to clear the message
    flashElement.textContent = message

    // Clear existing messages and add the new one
    flashContainer.innerHTML = ''
    flashContainer.appendChild(flashElement)

    // Scroll to the top to ensure the error is visible
    flashContainer.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
  }
}