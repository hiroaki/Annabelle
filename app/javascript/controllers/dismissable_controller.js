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
    const element = this.element;
    // 現在の高さ・余白・パディングを取得
    const currentHeight = element.offsetHeight;
    const styles = window.getComputedStyle(element);

    // アニメーション開始前に、インラインスタイルで現在値をセット
    element.style.height = `${currentHeight}px`;
    element.style.opacity = '1';
    element.style.marginTop = styles.marginTop;
    element.style.marginBottom = styles.marginBottom;
    element.style.paddingTop = styles.paddingTop;
    element.style.paddingBottom = styles.paddingBottom;

    // リフローを強制して、スタイルの変更を確実に反映
    void element.offsetHeight;

    // アニメーション用のクラスを追加
    element.classList.add('overflow-hidden', 'transition-all', 'duration-500');
    // 高さ・透明度・余白・パディングを0にしてアニメーション開始
    element.style.height = '0px';
    element.style.opacity = '0';
    element.style.marginTop = '0px';
    element.style.marginBottom = '0px';
    element.style.paddingTop = '0px';
    element.style.paddingBottom = '0px';

    // アニメーション終了時に要素を削除
    const handleTransitionEnd = (event) => {
      if (event.target !== element) return;
      if (event.propertyName !== 'height') return;

      element.removeEventListener('transitionend', handleTransitionEnd);
      element.remove();
    };
    element.addEventListener('transitionend', handleTransitionEnd);
  }
}
