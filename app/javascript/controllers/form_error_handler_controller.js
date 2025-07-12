import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    error413: String,
    error502: String,
    error503: String,
    error504: String,
    errorNetwork: String
  }

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
    const errorMessage = this.getErrorMessage(status)
    
    if (errorMessage) {
      this.displayFlashMessage(errorMessage)
    }
  }

  getErrorMessage(status) {
    const errorMapping = {
      413: this.error413Value,
      502: this.error502Value, 
      503: this.error503Value,
      504: this.error504Value
    }

    return errorMapping[status] || null
  }

  displayFlashMessage(message) {
    // Find the flash message container
    const flashContainer = document.getElementById('flash-message-container')
    
    if (!flashContainer) {
      console.error('Flash message container not found')
      return
    }

    // Create a flash message element that matches the existing Rails flash partial structure
    const flashElement = document.createElement('div')
    flashElement.className = 'p-4 mb-4 text-sm text-red-700 bg-red-100 rounded-lg'
    flashElement.setAttribute('role', 'alert')
    flashElement.setAttribute('data-controller', 'dismissable')
    flashElement.setAttribute('data-testid', 'flash-message')
    flashElement.textContent = message

    // Clear existing messages and add the new one
    flashContainer.innerHTML = ''
    flashContainer.appendChild(flashElement)

    // Scroll to the top to ensure the error is visible
    flashContainer.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
  }
}