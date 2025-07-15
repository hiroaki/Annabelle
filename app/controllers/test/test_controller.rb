# Test controller for simulating proxy errors during development
class Test::TestController < ApplicationController
  # Skip the X-App-Response header for proxy error simulation
  skip_before_action :set_app_response_header, only: [:proxy_error]
  
  # Skip authentication for testing (remove this in production)
  skip_before_action :authenticate_user!, if: -> { Rails.env.development? }

  def proxy_error
    status_code = params[:status]&.to_i || 413
    
    # Validate status code
    unless [413, 502, 503, 504].include?(status_code)
      status_code = 413
    end
    
    # Log for debugging
    Rails.logger.info "[TestController] Simulating proxy error with status #{status_code}"
    
    # Return the status code without the X-App-Response header
    # This simulates what a proxy would return
    head status_code
  end

  def app_error
    status_code = params[:status]&.to_i || 500
    
    # This will include the X-App-Response header
    # This simulates what the Rails app would return
    Rails.logger.info "[TestController] Simulating app error with status #{status_code}"
    
    render json: { error: "Simulated app error" }, status: status_code
  end

  def test_page
    # Simple test page with buttons to trigger errors
    render html: <<~HTML.html_safe
      <!DOCTYPE html>
      <html>
        <head>
          <title>Proxy Error Test Page</title>
          <meta name="viewport" content="width=device-width,initial-scale=1">
          #{csrf_meta_tags}
          #{stylesheet_link_tag "tailwind", "inter-font"}
        </head>
        <body data-controller="proxy-error-handler"
              data-proxy-error-handler-locale-value="#{I18n.locale}"
              data-proxy-error-handler-show-limits-value="#{ProxyConfiguration.show_limits?}"
              data-proxy-error-handler-request-size-limit-value="#{ProxyConfiguration.formatted_limit}">
          
          <div class="container mx-auto px-4 py-8">
            <h1 class="text-3xl font-bold mb-6">Proxy Error Handler Test</h1>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="bg-white p-6 rounded-lg shadow">
                <h2 class="text-xl font-semibold mb-4">Proxy Errors (No X-App-Response header)</h2>
                <div class="space-y-2">
                  <button onclick="testProxyError(413)" class="block w-full bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600">
                    Test 413 - Request Too Large
                  </button>
                  <button onclick="testProxyError(502)" class="block w-full bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600">
                    Test 502 - Bad Gateway
                  </button>
                  <button onclick="testProxyError(503)" class="block w-full bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600">
                    Test 503 - Service Unavailable
                  </button>
                  <button onclick="testProxyError(504)" class="block w-full bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600">
                    Test 504 - Gateway Timeout
                  </button>
                </div>
              </div>

              <div class="bg-white p-6 rounded-lg shadow">
                <h2 class="text-xl font-semibold mb-4">App Errors (With X-App-Response header)</h2>
                <div class="space-y-2">
                  <button onclick="testAppError(500)" class="block w-full bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
                    Test 500 - Internal Server Error
                  </button>
                  <button onclick="testAppError(404)" class="block w-full bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
                    Test 404 - Not Found
                  </button>
                  <button onclick="testAppError(422)" class="block w-full bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
                    Test 422 - Unprocessable Entity
                  </button>
                </div>
              </div>
            </div>

            <div class="mt-8 bg-gray-100 p-6 rounded-lg">
              <h3 class="text-lg font-semibold mb-2">Configuration</h3>
              <ul class="space-y-1 text-sm">
                <li><strong>Locale:</strong> #{I18n.locale}</li>
                <li><strong>Show Limits:</strong> #{ProxyConfiguration.show_limits?}</li>
                <li><strong>Request Size Limit:</strong> #{ProxyConfiguration.formatted_limit}</li>
              </ul>
            </div>
          </div>

          <script>
            function testProxyError(status) {
              fetch(`/test/proxy-error/${status}`)
                .catch(error => console.log('Expected error:', error));
            }

            function testAppError(status) {
              fetch(`/test/app-error/${status}`)
                .catch(error => console.log('App error (should not show proxy message):', error));
            }
          </script>
        </body>
      </html>
    HTML
  end
end