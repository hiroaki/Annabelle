import { Controller } from '@hotwired/stimulus'

function getMeta(name) {
  const element = document.head.querySelector(
    `meta[name='current-user-${name}']`
  );
  if (element) {
    return element.getAttribute('content');
  }
}

export default class extends Controller {
  static targets = ['owner', 'nonOwner']

  connect() {
    const ownerId = parseInt(this.element.dataset.ownerId, 10);
    const currentUserId = this.currentUser();

    if (ownerId === currentUserId) {
      this.show(this.ownerTarget);
      this.hide(this.nonOwnerTarget);
    } else {
      this.hide(this.ownerTarget);
      this.show(this.nonOwnerTarget);
    }
  }

  show(element) {
    element.classList.remove('hidden');
  }

  hide(element) {
    element.classList.add('hidden');
  }

  currentUser() {
    return parseInt(getMeta('id'), 10) || 0;
  }
}
