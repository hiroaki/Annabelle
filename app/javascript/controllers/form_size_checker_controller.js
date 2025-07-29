import { Controller } from "@hotwired/stimulus";
import { appendMessageToStorage, renderFlashMessages } from "flash_messages";

// Checks the total size of form data before submission.
// If the size exceeds the specified limit, shows an error message and cancels submission.
// Attach this controller to your form and add the following data attributes:
//    data-controller="form-size-checker"
//    data-form-size-checker-max-size-value="10485760"
//    data-form-size-checker-error-message-value="Message to display when size limit is exceeded"
//
// フォーム送信時に、その送信データサイズをチェックします。
// 上限値を超えている場合はメッセージを表示し、送信をキャンセルします。
// 対象のフォームにこのコントローラを接続させ、次に示す data 設定値を追加してください。
//    data-controller="form-size-checker"
//    data-form-size-checker-max-size-value="10485760"
//    data-form-size-checker-error-message-value="サイズ制限エラー時のメッセージ"
export default class extends Controller {
  static values = { maxSize: Number, errorMessage: String };

  check(event) {
    const form = this.element;
    const formData = new FormData(form);
    let totalSize = 0;

    for (const [_key, value] of formData.entries()) {
      if (value instanceof File) {
        totalSize += value.size;
      } else if (typeof value === "string") {
        totalSize += new Blob([value]).size;
      }
    }

    if (totalSize > this.maxSizeValue) {
      event.preventDefault();
      const errorMessage = this.errorMessageValue;
      if (errorMessage) {
        this.showError(errorMessage);
      }
    }
  }

  showError(message) {
    appendMessageToStorage(message, "alert");
    renderFlashMessages();
  }
}
