import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['preview']

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
    controller.previewTarget.innerHTML = '';
    controller.previewTarget.appendChild(evt.currentTarget.firstElementChild.cloneNode(true));
  }

  clearPreview(evt) {
    evt.preventDefault();

    const controller = this;
    controller.previewTarget.innerHTML = '';
  }
}
