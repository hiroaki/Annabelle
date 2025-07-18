import { Controller } from '@hotwired/stimulus'

/**
 * Flash Manager Controller
 * 
 * Manages unified Flash message display for both server-side and client-side messages.
 * Handles Turbo events for network errors, proxy errors, and HTTP status responses.
 * Supports accessibility, dismissable functionality, and future i18n integration.
 */
export default class extends Controller {
  static targets = ['container']
  
  connect() {
    // Create the flash container if it doesn't exist
    this.ensureFlashContainer()
    
    // Process any existing server-side flash messages after a short delay
    setTimeout(() => this.processExistingFlashMessages(), 100)
    
    // Set up Turbo event listeners
    this.setupTurboEventListeners()
    
    // Make this controller globally accessible
    window._flashManagerController = this
  }
  
  disconnect() {
    this.removeTurboEventListeners()
    if (window._flashManagerController === this) {
      delete window._flashManagerController
    }
  }
  
  ensureFlashContainer() {
    if (!this.hasContainerTarget) {
      const container = document.createElement('div')
      container.id = 'unified-flash-container'
      container.className = 'fixed top-4 left-1/2 transform -translate-x-1/2 z-50 w-full max-w-md px-4'
      container.setAttribute('data-flash-manager-target', 'container')
      this.element.appendChild(container)
    }
  }
  
  processExistingFlashMessages() {
    // Find existing flash messages in the DOM
    const existingFlashContainers = document.querySelectorAll('#flash-message-container, [data-testid="flash-message"]')
    
    existingFlashContainers.forEach(container => {
      if (container.id === 'unified-flash-container') return // Skip our own container
      
      const messages = container.querySelectorAll('[role="alert"]')
      messages.forEach(message => {
        this.extractAndMoveFlashMessage(message)
      })
    })
  }
  
  extractAndMoveFlashMessage(messageElement) {
    const text = messageElement.textContent.trim()
    const type = this.detectFlashType(messageElement)
    
    if (text) {
      this.addFlashMessage(type, text)
      // Remove the original message to avoid duplication
      messageElement.remove()
    }
  }
  
  detectFlashType(element) {
    const classList = element.classList.toString()
    if (classList.includes('text-red-700')) return 'alert'
    if (classList.includes('text-blue-700')) return 'notice'
    if (classList.includes('text-yellow-700')) return 'warning'
    return 'notice'
  }
  
  setupTurboEventListeners() {
    // Bind context for event handlers
    this.boundHandleSubmitEnd = this.handleSubmitEnd.bind(this)
    this.boundHandleFetchError = this.handleFetchError.bind(this)
    this.boundHandleFrameMissing = this.handleFrameMissing.bind(this)
    
    // Handle form submission errors
    document.addEventListener('turbo:submit-end', this.boundHandleSubmitEnd)
    
    // Handle fetch request errors (network, proxy, etc.)
    document.addEventListener('turbo:fetch-request-error', this.boundHandleFetchError)
    
    // Handle frame load errors
    document.addEventListener('turbo:frame-missing', this.boundHandleFrameMissing)
  }
  
  removeTurboEventListeners() {
    if (this.boundHandleSubmitEnd) {
      document.removeEventListener('turbo:submit-end', this.boundHandleSubmitEnd)
    }
    if (this.boundHandleFetchError) {
      document.removeEventListener('turbo:fetch-request-error', this.boundHandleFetchError)
    }
    if (this.boundHandleFrameMissing) {
      document.removeEventListener('turbo:frame-missing', this.boundHandleFrameMissing)
    }
  }
  
  handleSubmitEnd(event) {
    const { success, response } = event.detail
    
    if (!success && response) {
      const statusCode = response.status
      const message = this.getErrorMessageForStatus(statusCode)
      this.addFlashMessage('alert', message)
    }
  }
  
  handleFetchError(event) {
    const { error, response } = event.detail
    
    if (response) {
      // Network response error (4xx, 5xx)
      const statusCode = response.status
      const message = this.getErrorMessageForStatus(statusCode)
      this.addFlashMessage('alert', message)
    } else {
      // Network connectivity error
      this.addFlashMessage('alert', this.getNetworkErrorMessage())
    }
  }
  
  handleFrameMissing(event) {
    this.addFlashMessage('alert', 'The requested content could not be loaded.')
  }
  
  getErrorMessageForStatus(status) {
    // Future i18n integration point
    const messages = {
      400: 'Invalid request. Please check your input.',
      401: 'You are not authorized to perform this action.',
      403: 'Access forbidden. You may need to confirm your email.',
      404: 'The requested resource was not found.',
      422: 'The submitted data is invalid.',
      500: 'A server error occurred. Please try again later.',
      502: 'Service temporarily unavailable.',
      503: 'Service temporarily unavailable.',
      504: 'Request timeout. Please try again.'
    }
    
    // TODO: Replace with i18n translation when available
    // return I18n.t(`flash.errors.http_${status}`, { defaultValue: messages[status] })
    
    return messages[status] || `An error occurred (${status}). Please try again.`
  }
  
  getNetworkErrorMessage() {
    // Future i18n integration point
    // TODO: Replace with i18n translation when available
    // return I18n.t('flash.errors.network', { defaultValue: 'Network connection error...' })
    
    return 'Network connection error. Please check your internet connection and try again.'
  }
  
  // Public API for adding flash messages from other controllers or inline scripts
  addFlashMessage(type, message, options = {}) {
    const flashElement = this.createFlashElement(type, message, options)
    this.containerTarget.appendChild(flashElement)
    
    // Auto-dismiss after delay if specified
    if (options.autoDismiss !== false) {
      setTimeout(() => {
        this.dismissFlashMessage(flashElement)
      }, options.delay || 5000)
    }
    
    return flashElement
  }
  
  createFlashElement(type, message, options = {}) {
    const flashStyles = {
      alert: 'text-red-700 bg-red-100 border-red-200',
      notice: 'text-blue-700 bg-blue-100 border-blue-200',
      warning: 'text-yellow-700 bg-yellow-100 border-yellow-200'
    }
    
    const style = flashStyles[type] || flashStyles.notice
    
    const element = document.createElement('div')
    element.className = `p-4 mb-4 text-sm ${style} rounded-lg border relative transition-all duration-300`
    element.setAttribute('role', 'alert')
    element.setAttribute('aria-live', 'polite')
    element.setAttribute('data-controller', 'dismissable')
    element.setAttribute('data-testid', 'flash-message')
    
    if (options.id) {
      element.id = options.id
    }
    
    element.textContent = message
    
    // Add animation classes for entrance
    element.style.opacity = '0'
    element.style.transform = 'translateY(-10px)'
    
    // Trigger entrance animation
    requestAnimationFrame(() => {
      element.style.opacity = '1'
      element.style.transform = 'translateY(0)'
    })
    
    return element
  }
  
  dismissFlashMessage(element) {
    if (!element || !element.parentNode) return
    
    element.style.opacity = '0'
    element.style.transform = 'translateY(-10px)'
    
    setTimeout(() => {
      if (element.parentNode) {
        element.remove()
      }
    }, 300)
  }
  
  // Clear all flash messages
  clearAllFlashMessages() {
    const messages = this.containerTarget.querySelectorAll('[role="alert"]')
    messages.forEach(message => this.dismissFlashMessage(message))
  }
  
  // Support for server-side flash injection via turbo streams
  updateFromServer(html) {
    // Parse server HTML and extract flash messages
    const tempDiv = document.createElement('div')
    tempDiv.innerHTML = html
    
    const messages = tempDiv.querySelectorAll('[role="alert"]')
    messages.forEach(message => {
      this.extractAndMoveFlashMessage(message)
    })
  }
}