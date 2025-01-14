/*
コントローラ tooltips

このコントローラを指定した要素にツールチップの機能を追加します。

準備として、ツールチップ自体の要素を別途用意しておきます：

  <div class="tooltip hidden absolute bg-gray-800 text-white text-sm p-2 rounded-md max-w-xs z-10 whitespace-nowrap"></div>

そのうえで、ツールチップに表示させる文字列を、トリガー要素の属性 data-tooltip に追加します：

  <a ... data-tooltip="Contents in tooltip">

いくつかのトリガー要素にコントローラを仕込むことができますが、ツールチップ要素は全体で一つで十分です。

現在の実装において、表示する位置については適当です。現在のような内容にした動機としては、
ダウンロード・アイコンがある場所に、そのダウンロードのファイル名を表示させる目的によります。
小さな幅の A タグにこのコントローラを仕込み、その要素のすぐ右にツールチップを表示させます。

ツールチップ要素について。あらかじめの準備として div 要素を用意させずに connect 時に
それを createElement で生成し body に attach することも考えましたが、
HTML 側から見て暗黙のうちに何らかの要素が追加されることを嫌い（増えていくことを嫌い）、
現在の実装のようにしていますが、それを保守すべきという強い理由はありません。
*/

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const element = this.element;

    element.addEventListener('mouseenter', function(_evt) {
      const tooltip = document.querySelector('.tooltip');
      const text = element.getAttribute('data-tooltip');

      tooltip.textContent = text;

      const rect = element.getBoundingClientRect();
      tooltip.style.left = `${rect.right + 12}px`;
      tooltip.style.top = `${rect.top + window.scrollY}px`;
      tooltip.classList.remove('hidden');
    });

    element.addEventListener('mouseleave', function(_evt) {
      const tooltip = document.querySelector('.tooltip');
      tooltip.classList.add('hidden');
    });
  }
}
