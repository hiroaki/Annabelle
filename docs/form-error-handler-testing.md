# Testing Form Error Handler

## Manual Testing Instructions

The form error handler is designed to catch HTTP status errors that occur at the proxy level (before reaching Rails). Here's how to test it:

### Prerequisites
- Rails app running with the form error handler controller
- A proxy (like nginx, kamal-proxy) configured with size limits

### Test Scenarios

#### 1. Testing 413 "Request Entity Too Large"
- Configure your proxy to have a small body size limit (e.g., 1MB)
- Try to post a message with a large file attachment that exceeds the limit
- Expected: User sees a friendly error message instead of just console logs

#### 2. Testing 502/503/504 Gateway Errors
- Configure your proxy to return these status codes or temporarily take down the backend
- Try to submit a message
- Expected: User sees appropriate error messages for server unavailability

#### 3. Browser Console Testing
For testing without a real proxy, you can simulate errors in the browser console:

```javascript
// Simulate a 413 error
const form = document.querySelector('form[data-controller*="form-error-handler"]');
const event = new CustomEvent('turbo:submit-end', {
  detail: {
    success: false,
    response: { status: 413 }
  }
});
form.dispatchEvent(event);
```

### Expected Results
- Error messages appear in the flash message container at the top of the form
- Messages are localized (Japanese/English based on browser/app language)
- Users understand what went wrong and how to fix it
- No more silent failures where users think their message was posted

### Configuration
The error messages are defined in the i18n files:
- `config/locales/ja.yml` - Japanese messages
- `config/locales/en.yml` - English messages

Error types handled:
- 413: Request Entity Too Large (file size)
- 502: Bad Gateway (proxy issues)
- 503: Service Unavailable (server down)
- 504: Gateway Timeout (slow responses)