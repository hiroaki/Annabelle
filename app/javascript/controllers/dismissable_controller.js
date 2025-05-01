import { Controller } from '@hotwired/stimulus'

/* このコントローラを接続した要素に、 "x" ボタンを右上に追加し、その要素を取り除くことができるようにします。
  CSS に tailwind を利用していることが前提です。
  */
export default class extends Controller {
  connect() {
    const matchResult = this.element.classList.toString().match(/text-(\w+)-\d+/);
    const colorClass = matchResult ? matchResult[1] : 'gray';

    const closeButton = document.createElement('button');
    closeButton.innerHTML = '&times;';
    closeButton.setAttribute('type', 'button');
    closeButton.setAttribute('aria-label', 'Close');
    closeButton.className = `absolute top-2 right-2 text-${colorClass}-700 hover:text-${colorClass}-900`;
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
