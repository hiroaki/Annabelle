import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect() {
    const closeButton = document.createElement('button');
    closeButton.innerHTML = '&times;';
    closeButton.setAttribute('type', 'button');
    closeButton.setAttribute('aria-label', 'Close');
    closeButton.className = 'absolute top-2 right-2 text-blue-700 hover:text-blue-900';
    closeButton.addEventListener('click', () => this.dismiss());

    this.element.classList.add('relative');
    this.element.appendChild(closeButton);
  }

  dismiss() {
    this.element.classList.add(
      'transition-all', 'duration-500', 'opacity-0', 'max-h-0', 'overflow-hidden', 'py-0', 'mb-0'
    )

    setTimeout(() => {
      this.element.remove();
    }, 1000)
  }
}
