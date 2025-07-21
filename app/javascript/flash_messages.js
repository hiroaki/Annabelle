/**
 * Flash Message System - Client-side Integration
 *
 * A unified Flash message display system that handles both server-side and client-side messages.
 *
 * Background:
 * In traditional Rails applications, flash messages are rendered server-side in templates.
 * However, this approach cannot handle errors that occur before requests reach Rails
 * (e.g., proxy errors, network failures, client-side validation errors).
 *
 * This module moves flash message rendering to the client-side, enabling:
 * - Handling of proxy/network errors that never reach the Rails server
 * - Unified display mechanism for both server and client-generated messages
 * - Consistent user experience across all error scenarios
 *
 * Comparison with standard Rails flash usage:
 *
 * Standard Rails (server-side rendering):
 *   flash[:alert] = "Error message"
 *   # Rendered in template: <%= render 'shared/flash_storage' %>
 *   # Where shared/flash_storage contains:
 *   #   <div id="flash-storage" style="display: none;">
 *   #     <ul>
 *   #       <% flash.each do |type, message| %>
 *   #         <li data-type="<%= type %>"><%= message %></li>
 *   #       <% end %>
 *   #     </ul>
 *   #   </div>
 *   #   <div id="flash-message-container"></div>
 *
 * This system (client-side rendering):
 *   flash[:alert] = "Error message"  # Same Rails code
 *   # Messages stored in #flash-storage, rendered by JavaScript
 *
 * Key differences and rules:
 * 1. Server messages: Use standard Rails flash - works transparently
 * 2. Client messages: Use addFlashMessageToStorage(message, type)
 * 3. DOM structure: Requires #flash-storage and #flash-message-container elements
 * 4. Message types: 'alert', 'notice', 'warning' (same as Rails conventions)
 * 5. Styling: Uses Tailwind CSS classes, customizable via flashStyles object
 *
 * Features:
 * - Parses messages from #flash-storage and renders them to #flash-message-container
 * - Handles server-side flash messages via Turbo navigation and Turbo Stream updates
 * - Provides client-side error messages for HTTP errors when no server messages exist
 * - Supports multiple message types: alert, notice, warning
 * - Compatible with Rails flash system and Turbo framework
 *
 * Usage:
 * 1. Import and initialize: initializeFlashMessageSystem()
 * 2. Add client messages: addFlashMessageToStorage(message, type)
 * 3. Render messages: renderFlashMessages()
 *
 * Required DOM elements:
 * - #flash-storage: Hidden container for message data (managed by Rails)
 * - #flash-message-container: Visible container where messages are displayed
 */

function renderFlashMessages() {
  const storage = document.getElementById('flash-storage');
  const generalerrors = document.getElementById('general-error-messages');
  const container = document.getElementById('flash-message-container');

  if (!storage || !container) return;

  const ul = storage.querySelector('ul');
  if (!ul || ul.children.length === 0) return; // Early return for performance

  container.innerHTML = '';

  // Existing style definitions from original _flash.html.erb
  const flashStyles = {
    alert: 'text-red-700 bg-red-100',
    notice: 'text-blue-700 bg-blue-100',
    warning: 'text-yellow-700 bg-yellow-100'
  };

  ul.querySelectorAll('li').forEach(li => {
    const type = li.dataset.type || 'notice';
    const message = li.textContent.trim();

    // Skip empty messages
    if (!message) return;

    const div = document.createElement('div');

    // Use same styles and data attributes as original _flash.html.erb
    const style = flashStyles[type] || flashStyles['warning'];
    div.className = `p-4 mb-4 text-sm ${style} rounded-lg`;
    div.setAttribute('role', 'alert');
    div.setAttribute('data-testid', 'flash-message');
    div.setAttribute('data-controller', 'dismissable');
    div.textContent = message;

    container.appendChild(div);
  });

  storage.innerHTML = '';
  generalerrors.innerHTML = '';
}

function addFlashMessageToStorage(message, type = 'alert') {
  const storage = document.getElementById('flash-storage');
  if (!storage) {
    return;
  }

  // Don't add empty messages
  if (!message || !message.trim()) {
    return;
  }

  let ul = storage.querySelector('ul');
  if (!ul) {
    ul = document.createElement('ul');
    storage.appendChild(ul);
  }

  const li = document.createElement('li');
  li.dataset.type = type;
  li.textContent = message;
  ul.appendChild(li);

  // Don't auto-render - let caller decide when to render
  // This allows for batching multiple messages
}

// Initialize the flash message system
function initializeFlashMessageSystem() {
  document.addEventListener('turbo:load', function() {
    renderFlashMessages();
  });

  document.addEventListener("turbo:frame-load", function() {
    renderFlashMessages();
  });

  // Handle all flash messages (success + error) after DOM updates complete
  document.addEventListener('turbo:render', function(event) {
    handleFlashAfterRender(event);
  });

  // Setup custom turbo:after-stream-render event for Turbo Stream updates
  // This replaces MutationObserver with a cleaner event-driven approach
  //
  // Based on technique from Hotwired community discussion:
  // https://discuss.hotwired.dev/t/event-to-know-a-turbo-stream-has-been-rendered/1554/25
  //
  // The core idea is to hook into turbo:before-stream-render and wrap the original
  // render function to dispatch a custom event after rendering completes.
  // This provides a clean event-driven alternative to MutationObserver for detecting
  // when Turbo Stream updates have finished rendering.
  (function() {
    // Create custom event for after stream render
    const afterRenderEvent = new Event("turbo:after-stream-render");

    // Hook into turbo:before-stream-render to add our custom event
    document.addEventListener("turbo:before-stream-render", (event) => {
      const originalRender = event.detail.render;

      event.detail.render = function (streamElement) {
        originalRender(streamElement);
        document.dispatchEvent(afterRenderEvent);
      };
    });

    // Listen for our custom after-stream-render event
    document.addEventListener("turbo:after-stream-render", function() {
      renderFlashMessages();
    });
  })();

  function handleFlashAfterRender(event) {
    const status = event.detail.fetchResponse?.status;

    // First, check if server-side flash messages exist and render them
    const storage = document.getElementById('flash-storage');
    const ul = storage?.querySelector('ul');
    if (ul && ul.children.length > 0) {
      renderFlashMessages(); // Render server messages
      return;
    }

    // No server-side flash messages exist
    // Show client-side error messages only for HTTP error status
    if (!status || status < 400) {
      return; // No error status, or success status - nothing to do
    }

    // Check if messages were already rendered (edge case protection)
    const container = document.getElementById('flash-message-container');
    if (container && container.children.length > 0) {
      return; // Messages already displayed
    }

    // サーバー側で用意されたロケール済み汎用エラーメッセージ（general-error-messages UL）から
    // ステータスコードに応じたメッセージを取得して表示します。
    const generalerrors = document.getElementById('general-error-messages');
    let message = null;
    if (generalerrors && status >= 400) {
      const key = String(status);
      const li = generalerrors.querySelector(`li[data-status="${key}"]`);
      if (li) message = li.textContent.trim();
    }
    if (message) {
      addFlashMessageToStorage(message, 'alert');
    } else {
      console.error(`[FlashMessage] No error message defined for status: ${status}`);
    }

    renderFlashMessages();
  }

  // Network error handling
  document.addEventListener('turbo:fetch-request-error', function(event) {
    const storage = document.getElementById('flash-storage');
    const ul = storage?.querySelector('ul');
    if (ul && ul.children.length > 0) {
      return;
    }
    // general-error-messagesからnetworkエラー文言を取得
    const generalerrors = document.getElementById('general-error-messages');
    let message = null;
    if (generalerrors) {
      const li = generalerrors.querySelector('li[data-status="network"]');
      if (li) message = li.textContent.trim();
    }
    if (message) {
      addFlashMessageToStorage(message, 'alert');
    } else {
      console.error('[FlashMessage] No error message defined for network error');
    }
    renderFlashMessages();
  });
}

export {
  renderFlashMessages,
  addFlashMessageToStorage,
  initializeFlashMessageSystem
};
