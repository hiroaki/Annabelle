import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="proxy-error-handler"
export default class extends Controller {
  static values = { 
    locale: String,
    showLimits: Boolean,
    requestSizeLimit: String
  }

  connect() {
    // Set up global error handling for AJAX requests
    this.setupGlobalErrorHandling()
    
    // Listen for Turbo events to ensure error handling persists across navigation
    document.addEventListener('turbo:load', this.setupGlobalErrorHandling.bind(this))
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener('turbo:load', this.setupGlobalErrorHandling.bind(this))
  }

  setupGlobalErrorHandling() {
    // Only set up once per page load
    if (window._proxyErrorHandlerSetup) return
    window._proxyErrorHandlerSetup = true

    // Intercept fetch requests
    const originalFetch = window.fetch
    const self = this
    
    window.fetch = async (url, options) => {
      try {
        const response = await originalFetch(url, options)
        if (!response.ok) {
          self.handleErrorResponse(response, url)
        }
        return response
      } catch (error) {
        self.handleNetworkError(error, url)
        throw error
      }
    }

    // Intercept XMLHttpRequest (for older AJAX requests and Rails UJS)
    const originalXHROpen = XMLHttpRequest.prototype.open
    const originalXHRSend = XMLHttpRequest.prototype.send

    XMLHttpRequest.prototype.open = function(method, url, async) {
      this._method = method
      this._url = url
      this._proxyErrorHandler = self
      return originalXHROpen.apply(this, arguments)
    }

    XMLHttpRequest.prototype.send = function(body) {
      const xhr = this
      
      this.addEventListener('error', function() {
        xhr._proxyErrorHandler?.handleXHRError(xhr)
      })
      
      this.addEventListener('load', function() {
        if (xhr.status >= 400) {
          xhr._proxyErrorHandler?.handleXHRError(xhr)
        }
      })
      
      return originalXHRSend.apply(this, arguments)
    }
  }

  handleErrorResponse(response, url) {
    // Check if this is a proxy error (no X-App-Response header)
    const isAppResponse = response.headers.get('X-App-Response')
    
    if (!isAppResponse) {
      this.showProxyError(response.status, 'fetch', { url })
    }
  }

  handleXHRError(xhr) {
    // Check if this is a proxy error (no X-App-Response header)
    const isAppResponse = xhr.getResponseHeader('X-App-Response')
    
    if (!isAppResponse && xhr.status >= 400) {
      this.showProxyError(xhr.status, 'xhr', { url: xhr._url })
    }
  }

  handleNetworkError(error, url) {
    // Network errors are likely proxy-related
    this.showProxyError(0, 'network', { url, error: error.message })
  }

  showProxyError(statusCode, errorType = 'http', context = {}) {
    let messageKey
    let interpolations = {}

    switch (statusCode) {
      case 413:
        if (this.showLimitsValue && this.requestSizeLimitValue) {
          messageKey = 'errors.proxy.too_large_with_limit'
          interpolations = { limit: this.requestSizeLimitValue }
        } else {
          messageKey = 'errors.proxy.too_large'
        }
        break
      case 502:
        messageKey = 'errors.proxy.bad_gateway'
        break
      case 503:
        messageKey = 'errors.proxy.service_unavailable'
        break
      case 504:
        messageKey = 'errors.proxy.gateway_timeout'
        break
      case 0:
      default:
        messageKey = 'errors.proxy.generic'
        break
    }

    const message = this.translate(messageKey, interpolations)
    this.displayError(message, statusCode, context)
    
    // Log for debugging
    console.warn(`[ProxyError] ${statusCode} (${errorType}):`, message, context)
  }

  translate(key, interpolations = {}) {
    // Try to use i18n-js if available, otherwise fall back to embedded translations
    if (typeof I18n !== 'undefined' && I18n.t) {
      try {
        const translation = I18n.t(key, interpolations)
        if (!translation.includes('translation missing')) {
          return translation
        }
      } catch (e) {
        console.warn('[ProxyError] i18n-js translation failed:', e)
      }
    }
    
    // Fallback to embedded translations
    const translations = this.getTranslations()
    let translation = this.getNestedTranslation(translations, key)
    
    if (!translation) {
      return `Error: ${key}` // fallback if no translation found
    }

    // Handle interpolations
    Object.keys(interpolations).forEach(placeholder => {
      const regex = new RegExp(`%{${placeholder}}`, 'g')
      translation = translation.replace(regex, interpolations[placeholder])
    })

    return translation
  }

  getNestedTranslation(obj, key) {
    return key.split('.').reduce((o, k) => o && o[k], obj)
  }

  getTranslations() {
    // Default translations - these serve as fallback when i18n-js is not available
    const defaultTranslations = {
      en: {
        errors: {
          proxy: {
            too_large: "Request too large. The file or request size exceeds the maximum allowed limit.",
            too_large_with_limit: "Request too large. The file or request size exceeds the maximum allowed limit of %{limit}.",
            bad_gateway: "Service temporarily unavailable. Please try again later.",
            service_unavailable: "Service temporarily unavailable. Please try again later.",
            gateway_timeout: "Request timeout. The server took too long to respond.",
            generic: "Request failed due to proxy configuration. Please try again later."
          }
        }
      },
      ja: {
        errors: {
          proxy: {
            too_large: "リクエストサイズが大きすぎます。ファイルまたはリクエストサイズが上限を超えています。",
            too_large_with_limit: "リクエストサイズが大きすぎます。ファイルまたはリクエストサイズが上限（%{limit}）を超えています。",
            bad_gateway: "サービスが一時的に利用できません。しばらく経ってから再度お試しください。",
            service_unavailable: "サービスが一時的に利用できません。しばらく経ってから再度お試しください。",
            gateway_timeout: "リクエストがタイムアウトしました。サーバーの応答に時間がかかりすぎています。",
            generic: "プロキシ設定によりリクエストが失敗しました。しばらく経ってから再度お試しください。"
          }
        }
      }
    }

    const locale = this.localeValue || 'en'
    return defaultTranslations[locale] || defaultTranslations.en
  }

  displayError(message, statusCode = 0, context = {}) {
    // Remove any existing error messages first
    this.clearExistingErrors()
    
    const errorElement = document.createElement('div')
    errorElement.className = 'proxy-error-message fixed top-4 right-4 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded shadow-lg z-50 max-w-md animate-slide-in'
    errorElement.setAttribute('role', 'alert')
    errorElement.setAttribute('aria-live', 'assertive')
    
    errorElement.innerHTML = `
      <div class="flex">
        <div class="flex-1">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-red-800">
                Proxy Error ${statusCode ? `(${statusCode})` : ''}
              </h3>
              <div class="mt-2 text-sm text-red-700" data-message>
                ${message}
              </div>
            </div>
          </div>
        </div>
        <div class="ml-4">
          <button class="inline-flex text-red-400 hover:text-red-600 focus:outline-none focus:ring-2 focus:ring-red-500" data-dismiss>
            <span class="sr-only">Close</span>
            <svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
            </svg>
          </button>
        </div>
      </div>
    `
    
    document.body.appendChild(errorElement)

    // Set up dismiss functionality
    const dismissButton = errorElement.querySelector('[data-dismiss]')
    dismissButton.addEventListener('click', () => {
      this.removeErrorElement(errorElement)
    })

    // Auto-dismiss after 10 seconds
    setTimeout(() => {
      if (errorElement.parentNode) {
        this.removeErrorElement(errorElement)
      }
    }, 10000)

    // Focus management for accessibility
    setTimeout(() => {
      dismissButton.focus()
    }, 100)
  }

  clearExistingErrors() {
    const existingErrors = document.querySelectorAll('.proxy-error-message')
    existingErrors.forEach(error => this.removeErrorElement(error))
  }

  removeErrorElement(element) {
    if (element && element.parentNode) {
      element.style.opacity = '0'
      element.style.transform = 'translateX(100%)'
      setTimeout(() => {
        if (element.parentNode) {
          element.remove()
        }
      }, 300)
    }
  }
}

// Add CSS for animations
if (!document.querySelector('#proxy-error-styles')) {
  const style = document.createElement('style')
  style.id = 'proxy-error-styles'
  style.textContent = `
    .proxy-error-message {
      transition: all 0.3s ease-in-out;
    }
    .animate-slide-in {
      animation: slideIn 0.3s ease-out;
    }
    @keyframes slideIn {
      from {
        transform: translateX(100%);
        opacity: 0;
      }
      to {
        transform: translateX(0);
        opacity: 1;
      }
    }
  `
  document.head.appendChild(style)
}