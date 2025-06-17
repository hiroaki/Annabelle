import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['reaction', 'drawer'];

  connect() {
    this.isOpen = false;
    this.update();
  }

  toggle(event) {
    this.isOpen = !this.isOpen;
    this.update();
    event.currentTarget.blur();
  }

  update() {
    if (this.isOpen) {
      this.drawerTarget.classList.remove('-translate-x-full');
      this.drawerTarget.classList.add('translate-x-0');
      this.reactionTarget.classList.add('shadow-inner');

    } else {
      this.drawerTarget.classList.add('-translate-x-full');
      this.drawerTarget.classList.remove('translate-x-0');
      this.reactionTarget.classList.remove('shadow-inner');
    }
  }

  closeOnClick(event) {
    if (window.innerWidth < 640 && event.target.tagName === 'A') {
      this.isOpen = false
      this.update();
    }
  }
}
