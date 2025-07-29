// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "channels"
import "lib/lazysizes.min"
import { initializeFlashMessageSystem } from "flash_messages"

// https://developer.mozilla.org/ja/docs/Web/API/Document/DOMContentLoaded_event
// > if チェックと addEventListener() 呼び出しの間に文書が読み込まれることはあり得ません。
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initializeFlashMessageSystem);
} else {
  initializeFlashMessageSystem();
}
