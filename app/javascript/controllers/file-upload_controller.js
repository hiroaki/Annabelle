import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['fileInput', 'dropZone', 'reactionZone'];

  connect() {
    // NOTE: dragCounter は、リスナー以外の親子要素でも同様のドラッグ関連イベントが
    // 複数同時に発生することによって、その都度見た目を変えたりしないようにするための工夫です。
    this.dragCounter = 0;
    this.bindDragAndDropEvents();
  }

  bindDragAndDropEvents() {
    this.dropZoneTargets.forEach((dropZone) => {
      dropZone.addEventListener('dragenter', this.handleDragEnter.bind(this));
      dropZone.addEventListener('dragleave', this.handleDragLeave.bind(this));
      dropZone.addEventListener('dragover', this.preventDefaults.bind(this));
      dropZone.addEventListener('drop', this.handleDrop.bind(this));
    });
  }

  handleDragEnter(event) {
    event.preventDefault();
    this.dragCounter += 1;
    this.#turnOnReaction(event);
  }

  handleDragLeave(event) {
    event.preventDefault();
    this.dragCounter -= 1;

    if (this.dragCounter === 0) {
      this.#turnOffReaction(event);
    }
  }

  preventDefaults(event) {
    event.preventDefault();
    event.stopPropagation();
  }

  handleDrop(event) {
    event.preventDefault();

    const files = event.dataTransfer.files;
    if (files.length > 0) {
      this.fileInputTarget.files = files;
      this.fileInputTarget.dispatchEvent(new Event('change'));
    }

    this.dragCounter = 0;
    this.#turnOffReaction(event);
  }

  #turnOnReaction(event) {
    if (this.reactionZoneTarget) {
      this.reactionZoneTarget.classList.add(this.#reactionClass(this.reactionZoneTarget));
    } else {
      event.currentTarget.classList.add(this.reactionClass(this.currentTarget));
    }
  }

  #turnOffReaction(event) {
    if (this.reactionZoneTarget) {
      this.reactionZoneTarget.classList.remove(this.#reactionClass(this.reactionZoneTarget));
    } else {
      event.currentTarget.classList.remove(this.reactionClass(this.currentTarget));
    }
  }

  #reactionClass(elem) {
    return elem.dataset['reactionClass'] || 'bg-red-100';
  }
}
