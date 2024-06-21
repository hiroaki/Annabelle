import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log('Hello, Stimulus!', this.element)
  }

  resetForm(evt) {
    const form = evt.target.closest('form')
    form.reset()
  }
}
