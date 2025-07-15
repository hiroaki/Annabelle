import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["errorContainer"]

  connect() {
    // Listen for Turbo fetch request errors
    document.addEventListener("turbo:fetch-request-error", this.handleFetchError.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:fetch-request-error", this.handleFetchError.bind(this))
  }

  handleFetchError(event) {
    const { response } = event.detail
    
    // Handle 413 Request Entity Too Large specifically
    if (response && response.status === 413) {
      this.showError("リクエストサイズが大きすぎます")
    }
    // TODO: Add support for other proxy error status codes (502, 504, etc.)
    // TODO: Implement i18n support for error messages
  }

  showError(message) {
    // Create error element
    const errorElement = document.createElement("div")
    errorElement.className = "bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4"
    errorElement.setAttribute("role", "alert")
    errorElement.innerHTML = `
      <span class="block sm:inline">${message}</span>
      <span class="absolute top-0 bottom-0 right-0 px-4 py-3">
        <button class="text-red-700 hover:text-red-900" onclick="this.parentElement.parentElement.remove()">
          ×
        </button>
      </span>
    `
    errorElement.className += " relative"

    // Insert error at the beginning of the error container
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.insertBefore(errorElement, this.errorContainerTarget.firstChild)
    } else {
      // Fallback: show alert if no error container target is found
      alert(message)
    }

    // Auto-remove after 5 seconds
    setTimeout(() => {
      if (errorElement.parentNode) {
        errorElement.remove()
      }
    }, 5000)
  }
}