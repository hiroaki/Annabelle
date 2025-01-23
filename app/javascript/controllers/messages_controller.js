import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['preview', 'modal', 'modalBody']

  resetForm(evt) {
    const form = evt.target.closest('form')
    form.reset()
  }

  changePreview(evt) {
    evt.preventDefault();

    const content = evt.currentTarget.querySelector('img, video').cloneNode(true);

    if (this.isDisplayed(this.previewTarget)) {
      this.clearPreview();
      this.previewTarget.appendChild(content);
    } else {
      this.clearModal();
      this.modalBodyTarget.appendChild(content);
      this.openModal();
    }
  }

  isDisplayed(elem) {
    return elem.offsetParent !== null
  }

  handlerClearPreview(evt) {
    this.clearPreview();
  }

  handlerCloseModal(evt) {
    this.closeModal();
  }

  clearPreview() {
    this.previewTarget.innerHTML = '';
  }

  clearModal() {
    this.modalBodyTarget.innerHTML = '';
  }

  openModal() {
    this.modalTarget.classList.remove('hidden');
  }

  closeModal() {
    this.modalTarget.classList.add('hidden');
  }
}
