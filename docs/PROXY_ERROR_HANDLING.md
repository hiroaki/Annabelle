# Configuration and testing instructions for Proxy Error Handling

## Overview

This implementation adds proxy error handling to distinguish between errors from the proxy (e.g., kamal-proxy) and errors from the Rails application itself.

## Features

1. **Custom Header Detection**: Rails responses include `X-App-Response: true` header
2. **Proxy Error Messages**: Internationalized error messages for common proxy errors
3. **Configurable Limits**: Request size limits can be configured via environment variables or Rails config
4. **Client-side Error Display**: JavaScript automatically detects and displays proxy errors
5. **Stimulus Integration**: Works seamlessly with Hotwire Turbo Drive navigation
6. **Accessibility**: Error messages include proper ARIA attributes and focus management

## Installation & Setup

### 1. Dependencies

Ensure the following gems are in your Gemfile:

```ruby
gem "i18n-js", "~> 4.2"
```

Then run:

```bash
bundle install
```

### 2. Import Map Configuration

The system requires the i18n-js library to be available. It's already configured in `config/importmap.rb`:

```ruby
pin "i18n-js", to: "https://ga.jspm.io/npm:i18n-js@4.2.3/src/index.js"
```

### 3. Layout Integration

The proxy error handler is automatically included in the main application layout. If you need to add it to other layouts, include the data attributes:

```erb
<body data-controller="proxy-error-handler"
      data-proxy-error-handler-locale-value="<%= I18n.locale %>"
      data-proxy-error-handler-show-limits-value="<%= ProxyConfiguration.show_limits? %>"
      data-proxy-error-handler-request-size-limit-value="<%= ProxyConfiguration.formatted_limit %>">
```

Or use the helper method:

```erb
<body <%= proxy_error_data_attributes %>>
```

## Configuration

### Environment Variables

- `PROXY_REQUEST_SIZE_LIMIT`: Set request size limit (e.g., "100MB", "1GB")
- `PROXY_SHOW_LIMITS`: Whether to show limits in error messages ("true" or "false")

### Rails Configuration

In `config/application.rb` or environment-specific files:

```ruby
config.proxy_settings = {
  request_size_limit: 100.megabytes,
  show_limits: true
}
```

### Locale Files

Error messages are automatically included in your locale files. You can customize them in:

- `config/locales/en.yml`
- `config/locales/ja.yml`

Example customization:

```yaml
en:
  errors:
    proxy:
      too_large: "Your custom message for large requests"
      too_large_with_limit: "Request exceeds %{limit} limit"
```

## Error Messages

The system handles these HTTP status codes:

- **413 Request Entity Too Large**: File/request size exceeds limit
- **502 Bad Gateway**: Service temporarily unavailable  
- **503 Service Unavailable**: Service temporarily unavailable
- **504 Gateway Timeout**: Request timeout
- **Network Errors**: Connection failures

## Testing

### Development Test Page

Visit `/test/test-page` in development mode to access a test interface for manually triggering proxy errors.

### Manual Testing

To test the proxy error handling:

1. **Start the Rails server**
2. **Visit the test page**: `http://localhost:3000/test/test-page`
3. **Click the proxy error buttons** to simulate different error types
4. **Observe client-side error messages** displayed in the UI

### Simulating Proxy Errors

For testing purposes, you can use the included test endpoints:

- `/test/proxy-error/413` - Simulates 413 Request Too Large
- `/test/proxy-error/502` - Simulates 502 Bad Gateway
- `/test/proxy-error/503` - Simulates 503 Service Unavailable
- `/test/proxy-error/504` - Simulates 504 Gateway Timeout

These endpoints omit the `X-App-Response` header to simulate proxy responses.

### Production Testing

In production, you can test by:

1. **Uploading large files** that exceed proxy limits
2. **Monitoring network requests** in browser developer tools
3. **Checking server logs** for proxy-related errors

### Automated Testing

Run the included RSpec tests:

```bash
bundle exec rspec spec/lib/proxy_configuration_spec.rb
bundle exec rspec spec/lib/proxy_error_translations_spec.rb  
bundle exec rspec spec/requests/application_controller_proxy_error_spec.rb
```

## Browser Console Testing

You can test the error handler in browser console:

```javascript
// Simulate a proxy error (no X-App-Response header)
fetch('/test/proxy-error/413').catch(console.log)

// Simulate an app error (with X-App-Response header)  
fetch('/test/app-error/500').catch(console.log)
```

## Customization

### Adding New Error Types

1. Add new error messages to `config/locales/en.yml` and `config/locales/ja.yml`
2. Update the `showProxyError` method in `proxy_error_handler_controller.js`

### Styling Error Messages

The error messages use Tailwind CSS classes. Modify the `displayError` method to customize styling:

```javascript
// In proxy_error_handler_controller.js
displayError(message, statusCode = 0, context = {}) {
  // Customize the errorElement.className here
  errorElement.className = 'your-custom-classes'
  // ...
}
```

### Changing Display Duration

Modify the timeout in `displayError` method (currently 10 seconds):

```javascript
// Auto-dismiss after custom duration
setTimeout(() => {
  if (errorElement.parentNode) {
    this.removeErrorElement(errorElement)
  }
}, 15000) // 15 seconds instead of 10
```

### Using with Specific Forms or Components

You can add the error handler to specific elements instead of the entire page:

```erb
<form data-controller="proxy-error-handler" 
      data-proxy-error-handler-locale-value="<%= I18n.locale %>"
      data-proxy-error-handler-show-limits-value="<%= ProxyConfiguration.show_limits? %>"
      data-proxy-error-handler-request-size-limit-value="<%= ProxyConfiguration.formatted_limit %>">
  <!-- form content -->
</form>
```

## Troubleshooting

### Error Messages Not Showing

1. **Check browser console** for JavaScript errors
2. **Verify Stimulus is loaded** properly
3. **Ensure locale files contain** the proxy error messages
4. **Check network tab** to confirm missing `X-App-Response` header

### Wrong Language Messages

1. **Verify `I18n.locale`** is set correctly
2. **Check locale file structure** matches expected format
3. **Ensure translations exist** for current locale

### Configuration Not Applied

1. **Restart Rails server** after changing configuration
2. **Check environment variables** are properly set
3. **Verify ProxyConfiguration class** can access the settings

## Security Considerations

- Test endpoints are only available in development mode
- Error messages don't expose sensitive server information
- Custom headers are added to all Rails responses, not just errors
- Error handling gracefully degrades if JavaScript is disabled