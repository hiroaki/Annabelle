/**
 * Flash Message System - Client-side Integration
 * 
 * Implements the plan from issue #27 for unified Flash message display.
 * Parses messages from #flash-storage and renders them to #flash-message-container.
 */

function renderFlashMessages() {
  const storage = document.getElementById('flash-storage');
  const container = document.getElementById('flash-message-container');
  
  if (!storage || !container) return;
  
  const ul = storage.querySelector('ul');
  if (!ul || ul.children.length === 0) return; // Early return for performance
  
  container.innerHTML = '';
  
  // Store count for debugging and add timestamp
  const messageCount = ul.children.length;
  container.setAttribute('data-message-count', messageCount);
  container.setAttribute('data-last-render', new Date().getTime());
  
  // Existing style definitions from original _flash.html.erb
  const flashStyles = {
    alert: 'text-red-700 bg-red-100',
    notice: 'text-blue-700 bg-blue-100',
    warning: 'text-yellow-700 bg-yellow-100'
  };
  
  // Convert to array to avoid live collection issues
  const liElements = Array.from(ul.querySelectorAll('li'));
  
  liElements.forEach((li, index) => {
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
    div.setAttribute('data-message-index', index);
    div.setAttribute('data-message-type', type);
    div.textContent = message;
    
    container.appendChild(div);
  });
  
  ul.innerHTML = '';
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
}

// Function to process flash messages immediately when DOM is ready
function processFlashMessages() {
  // Check if DOM is ready, if not wait for DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', renderFlashMessages);
  } else {
    // DOM is already ready, process immediately
    renderFlashMessages();
  }
}

// Event handling - process flash messages on page load and navigation
document.addEventListener('DOMContentLoaded', function() {
  renderFlashMessages();
});

document.addEventListener('turbo:load', function() {
  renderFlashMessages();
});

// Error handling for turbo:submit-end - handle form submission errors
document.addEventListener('turbo:submit-end', function(event) {
  const status = event.detail.fetchResponse?.status;
  
  // For successful responses, flash messages will be handled by turbo streams
  if (status >= 200 && status < 300) {
    return;
  }
  
  // For error responses, check if server provided flash messages first
  const storage = document.getElementById('flash-storage');
  const ul = storage?.querySelector('ul');
  
  // Server-side Flash priority (simple competition avoidance)
  if (ul && ul.children.length > 0) {
    renderFlashMessages(); // Render the server messages
    return;
  }

  // Add client-side error messages for specific status codes
  if (status === 413) {
    addFlashMessageToStorage('ファイルサイズが大きすぎます（413エラー）', 'alert');
    renderFlashMessages();
  } else if (status === 503) {
    addFlashMessageToStorage('サービスが一時的に利用できません（503エラー）', 'alert');
    renderFlashMessages();
  } else if (status >= 400 && status < 500) {
    addFlashMessageToStorage('リクエストに問題があります（4xxエラー）', 'alert');
    renderFlashMessages();
  } else if (status >= 500) {
    addFlashMessageToStorage('サーバーエラーが発生しました（5xxエラー）', 'alert');
    renderFlashMessages();
  }
});

// Handle turbo stream updates - this is the key for server-side flash messages
document.addEventListener('turbo:before-stream-render', function(event) {
  // Try multiple ways to detect if this is a flash-storage update
  const target = event.target?.id || 
                 event.detail?.render?.newStream?.getAttribute('target') ||
                 event.detail?.newStream?.getAttribute('target');
  
  if (target === 'flash-storage') {
    // Clear any existing rendered messages to avoid duplication
    const container = document.getElementById('flash-message-container');
    if (container) {
      container.innerHTML = '';
    }
  }
});

document.addEventListener('turbo:after-stream-render', function(event) {
  // Always check for flash messages after any turbo stream render
  const storage = document.getElementById('flash-storage');
  if (storage) {
    const ul = storage.querySelector('ul');
    if (ul && ul.children.length > 0) {
      // Add debugging attribute to track stream renders
      storage.setAttribute('data-last-stream-render', new Date().getTime());
      renderFlashMessages();
    }
  }
});

// Network error handling
document.addEventListener('turbo:fetch-request-error', function(event) {
  const storage = document.getElementById('flash-storage');
  const ul = storage?.querySelector('ul');
  if (ul && ul.children.length > 0) {
    return;
  }
  addFlashMessageToStorage('ネットワークエラーが発生しました', 'alert');
  renderFlashMessages();
});

// Make functions globally available for Turbo Stream calls and testing
window.renderFlashMessages = renderFlashMessages;
window.addFlashMessageToStorage = addFlashMessageToStorage;

// Debug function to inspect storage state
window.debugFlashStorage = function() {
  const storage = document.getElementById('flash-storage');
  const container = document.getElementById('flash-message-container');
  
  console.log('=== Flash Storage Debug ===');
  console.log('Storage element:', !!storage);
  console.log('Container element:', !!container);
  
  if (storage) {
    const ul = storage.querySelector('ul');
    console.log('Storage ul element:', !!ul);
    if (ul) {
      console.log('Storage ul children count:', ul.children.length);
      Array.from(ul.children).forEach((li, index) => {
        console.log(`Storage li ${index}:`, li.dataset.type, li.textContent);
      });
    }
    console.log('Storage innerHTML:', storage.innerHTML);
  }
  
  if (container) {
    console.log('Container children count:', container.children.length);
    console.log('Container innerHTML:', container.innerHTML);
  }
};