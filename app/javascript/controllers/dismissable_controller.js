import { Controller } from '@hotwired/stimulus'

/* このコントローラを接続した要素に、 "x" ボタンを右上に追加し、その要素を取り除くことができるようにします。
  CSS に tailwind を利用していることが前提です。
  統合Flash システムと互換性があります。
  */
export default class extends Controller {
  connect() {
    // Don't add close button if it already exists
    if (this.element.querySelector('[data-dismiss-button]')) {
      return
    }
    
    const matchResult = this.element.classList.toString().match(/text-(\w+)-\d+/);
    const colorClass = matchResult ? matchResult[1] : 'gray';

    const closeButton = document.createElement('button');
    closeButton.innerHTML = '&times;';
    closeButton.setAttribute('type', 'button');
    closeButton.setAttribute('aria-label', 'Close');
    closeButton.setAttribute('data-dismiss-button', 'true');
    closeButton.className = `absolute top-2 right-2 text-${colorClass}-700 hover:text-${colorClass}-900 text-lg leading-none`;
    closeButton.addEventListener('click', () => this.dismiss());

    this.element.classList.add('relative');
    this.element.appendChild(closeButton);
  }

  dismiss() {
    // Use the global Flash API if available for consistent behavior
    if (window.Flash) {
      const flashManager = window.Flash.getFlashManager()
      if (flashManager) {
        flashManager.dismissFlashMessage(this.element)
        return
      }
    }
    
    // Fallback to original dismissal logic
    this.element.classList.add(
      'transition-all', 'duration-500', 'opacity-0', 'max-h-0', 'overflow-hidden', 'py-0', 'mb-0'
    )

    setTimeout(() => {
      this.element.remove();
    }, 1000)
  }
}
