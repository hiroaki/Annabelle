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
  
  // Existing style definitions from original _flash.html.erb
  const flashStyles = {
    alert: 'text-red-700 bg-red-100',
    notice: 'text-blue-700 bg-blue-100',
    warning: 'text-yellow-700 bg-yellow-100'
  };
  
  ul.querySelectorAll('li').forEach(li => {
    const type = li.dataset.type || 'notice';
    const message = li.textContent;
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
  
  ul.innerHTML = '';
}

function addFlashMessageToStorage(message, type = 'alert') {
  const storage = document.getElementById('flash-storage');
  if (!storage) return;
  
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

// Function to process flash messages with a slight delay to ensure DOM is ready
function processFlashMessages() {
  setTimeout(function() {
    renderFlashMessages();
  }, 10);
}

// Simple event handling
document.addEventListener('DOMContentLoaded', processFlashMessages);
document.addEventListener('turbo:load', processFlashMessages);

// Error handling for turbo:submit-end
document.addEventListener('turbo:submit-end', function(event) {
  const status = event.detail.fetchResponse?.status;
  const storage = document.getElementById('flash-storage');
  const ul = storage?.querySelector('ul');
  
  // Server-side Flash priority (simple competition avoidance)
  if (ul && ul.children.length > 0) return;

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

// Network error handling
document.addEventListener('turbo:fetch-request-error', function(event) {
  const storage = document.getElementById('flash-storage');
  const ul = storage?.querySelector('ul');
  if (ul && ul.children.length > 0) return;
  addFlashMessageToStorage('ネットワークエラーが発生しました', 'alert');
  renderFlashMessages();
});

// Make functions globally available for Turbo Stream calls and testing
window.renderFlashMessages = renderFlashMessages;
window.addFlashMessageToStorage = addFlashMessageToStorage;