/**
 * Flash Message Utilities
 * 
 * Global utilities for working with the unified Flash message system.
 * These functions can be used by inline scripts, Turbo streams, and other JavaScript code.
 */

// Global Flash API
window.Flash = {
  /**
   * Add a flash message
   * @param {string} type - 'alert', 'notice', or 'warning'
   * @param {string} message - The message text
   * @param {object} options - Additional options (autoDismiss, delay, id)
   */
  add(type, message, options = {}) {
    const flashManager = this.getFlashManager()
    if (flashManager) {
      return flashManager.addFlashMessage(type, message, options)
    } else {
      console.warn('Flash Manager not found. Message:', message)
      return null
    }
  },

  /**
   * Add an alert message
   * @param {string} message - The alert message
   * @param {object} options - Additional options
   */
  alert(message, options = {}) {
    return this.add('alert', message, options)
  },

  /**
   * Add a notice message
   * @param {string} message - The notice message
   * @param {object} options - Additional options
   */
  notice(message, options = {}) {
    return this.add('notice', message, options)
  },

  /**
   * Add a warning message
   * @param {string} message - The warning message
   * @param {object} options - Additional options
   */
  warning(message, options = {}) {
    return this.add('warning', message, options)
  },

  /**
   * Clear all flash messages
   */
  clear() {
    const flashManager = this.getFlashManager()
    if (flashManager) {
      flashManager.clearAllFlashMessages()
    }
  },

  /**
   * Get the flash manager controller instance
   * @returns {object|null} The flash manager controller
   */
  getFlashManager() {
    // Check for global controller reference first
    if (window._flashManagerController) {
      return window._flashManagerController
    }
    
    // Fallback: find by DOM element
    const element = document.querySelector('[data-controller*="flash-manager"]')
    if (!element) return null
    
    // Use Stimulus controller lookup if available
    const app = window.Stimulus || document.documentElement.stimulus
    if (app) {
      return app.getControllerForElementAndIdentifier(element, 'flash-manager')
    }
    
    return null
  },

  /**
   * Initialize server-side flash messages (called on page load)
   */
  initServerFlash() {
    const flashManager = this.getFlashManager()
    if (flashManager) {
      flashManager.processExistingFlashMessages()
    }
  }
}

// Auto-initialize on DOM content loaded and Turbo events
document.addEventListener('DOMContentLoaded', () => {
  setTimeout(() => Flash.initServerFlash(), 100)
})

document.addEventListener('turbo:load', () => {
  setTimeout(() => Flash.initServerFlash(), 100)
})

// Make Flash API available globally
export default window.Flash