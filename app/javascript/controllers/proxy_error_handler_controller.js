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
  }

  setupGlobalErrorHandling() {
    // Intercept fetch requests
    const originalFetch = window.fetch
    window.fetch = async (url, options) => {
      try {
        const response = await originalFetch(url, options)
        if (!response.ok) {
          this.handleErrorResponse(response)
        }
        return response
      } catch (error) {
        this.handleNetworkError(error)
        throw error
      }
    }

    // Intercept XMLHttpRequest (for older AJAX requests)
    const originalXHROpen = XMLHttpRequest.prototype.open
    const originalXHRSend = XMLHttpRequest.prototype.send
    const self = this

    XMLHttpRequest.prototype.open = function(method, url, async) {
      this._method = method
      this._url = url
      return originalXHROpen.apply(this, arguments)
    }

    XMLHttpRequest.prototype.send = function(body) {
      this.addEventListener('error', function() {
        self.handleXHRError(this)
      })
      this.addEventListener('load', function() {
        if (this.status >= 400) {
          self.handleXHRError(this)
        }
      })
      return originalXHRSend.apply(this, arguments)
    }
  }

  handleErrorResponse(response) {
    // Check if this is a proxy error (no X-App-Response header)
    const isAppResponse = response.headers.get('X-App-Response')
    
    if (!isAppResponse) {
      this.showProxyError(response.status)
    }
  }

  handleXHRError(xhr) {
    // Check if this is a proxy error (no X-App-Response header)
    const isAppResponse = xhr.getResponseHeader('X-App-Response')
    
    if (!isAppResponse && xhr.status >= 400) {
      this.showProxyError(xhr.status)
    }
  }

  handleNetworkError(error) {
    // Network errors are likely proxy-related
    this.showProxyError(0, 'network')
  }

  showProxyError(statusCode, errorType = 'http') {
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
    this.displayError(message)
  }

  translate(key, interpolations = {}) {
    // Simple translation function - in a real implementation, 
    // this would use i18n-js when available
    const translations = this.getTranslations()
    
    let translation = this.getNestedTranslation(translations, key)
    
    if (!translation) {
      return key // fallback to key if translation not found
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
    // Default translations - these would be loaded from i18n-js in production
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

  displayError(message) {
    // Check if there's already an error display element
    let errorElement = document.querySelector('.proxy-error-message')
    
    if (!errorElement) {
      errorElement = document.createElement('div')
      errorElement.className = 'proxy-error-message fixed top-4 right-4 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded shadow-lg z-50 max-w-md'
      errorElement.innerHTML = `
        <div class="flex">
          <div class="flex-1">
            <strong class="font-bold">Error: </strong>
            <span class="block sm:inline" data-message></span>
          </div>
          <div class="pl-3">
            <button class="text-red-500 hover:text-red-700" data-dismiss>
              <span class="sr-only">Close</span>
              <svg class="h-4 w-4 fill-current" viewBox="0 0 20 20">
                <path d="M14.348 14.849a1.2 1.2 0 0 1-1.697 0L10 11.819l-2.651 3.029a1.2 1.2 0 1 1-1.697-1.697l2.758-3.15-2.759-3.152a1.2 1.2 0 1 1 1.697-1.697L10 8.183l2.651-3.031a1.2 1.2 0 1 1 1.697 1.697l-2.758 3.152 2.758 3.15a1.2 1.2 0 0 1 0 1.698z"/>
              </svg>
            </button>
          </div>
        </div>
      `
      document.body.appendChild(errorElement)

      // Set up dismiss functionality
      const dismissButton = errorElement.querySelector('[data-dismiss]')
      dismissButton.addEventListener('click', () => {
        errorElement.remove()
      })

      // Auto-dismiss after 10 seconds
      setTimeout(() => {
        if (errorElement.parentNode) {
          errorElement.remove()
        }
      }, 10000)
    }

    // Update message
    const messageSpan = errorElement.querySelector('[data-message]')
    messageSpan.textContent = message

    // Make sure it's visible
    errorElement.style.display = 'block'
  }
}