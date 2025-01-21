import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['preview', 'modal', 'modalBody']

  connect() {
    console.log('Hello, Stimulus!', this.element.id)
  }

  resetForm(evt) {
    const form = evt.target.closest('form')
    form.reset()
  }

  changePreview(evt) {
    evt.preventDefault();

    const controller = this;
    const content = evt.currentTarget.firstElementChild.cloneNode(true);
    controller.modalBodyTarget.innerHTML = '';
    controller.modalBodyTarget.appendChild(content);

    this.openModal();
  }

  clearPreview(evt) {
    evt.preventDefault();

    const controller = this;
    controller.modalBodyTarget.innerHTML = '';
  }

  openModal() {
    this.modalTarget.classList.remove('hidden');
  }

  closeModal() {
    this.modalTarget.classList.add('hidden');
  }
}
