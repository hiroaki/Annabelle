import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['preview']

  connect() {
    console.log('Hello, Stimulus!', this.element)
  }

  resetForm(evt) {
    const form = evt.target.closest('form')
    form.reset()
  }

  changePreview(evt) {
    evt.preventDefault();

    const controller = this;
    const content_type = evt.currentTarget.dataset.type;
    const data_url = evt.currentTarget.dataset.url;

    if (content_type == 'image/jpeg' || content_type == 'image/png' || content_type == 'image/gif') {
      controller.previewTarget.innerHTML = '<img class="fitting-width" src="'+ data_url +'">';
    }
    else if (content_type == 'video/mp4' || content_type == 'video/quicktime') {
      controller.previewTarget.innerHTML = '<video class="fitting-width" src="'+ data_url +'" controls></video>';
    }
  }

  clearPreview(evt) {
    evt.preventDefault();

    const controller = this;
    controller.previewTarget.innerHTML = '';
  }
}
