import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['fileInput', 'dropZone', 'reactionZone', 'standbyFilesZone'];

  connect() {
    // NOTE: dragCounter は、リスナー以外の親子要素でも同様のドラッグ関連イベントが
    // 複数同時に発生することによって、その都度見た目を変えたりしないようにするための工夫です。
    this.dragCounter = 0;
    this.bindDragAndDropEvents();
  }

  resetForm(evt) {
    const form = evt.target.closest('form');
    form.reset();
    this.clearPreviews();
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

  changeAttachments(event) {
    this.renderPreviews();
  }

  renderPreviews() {
    this.clearPreviews();

    Array.from(this.fileInputTarget.files).forEach((file, index) => {
      const preview = document.createElement('div');
      preview.className = 'relative inline-block w-10 h-10 mr-2';

      if (file.type.startsWith('image/')) {
        const img = document.createElement('img');
        img.src = URL.createObjectURL(file);
        img.className = 'w-full h-full object-cover rounded-sm';
        preview.appendChild(img);
      } else {
        const icon = document.createElement('div');
        icon.className = 'w-full h-full flex items-center justify-center bg-gray-200 rounded-sm';
        icon.innerHTML = '📄';
        preview.appendChild(icon);
      }

      // 削除ボタン
      const removeButton = document.createElement('button');
      removeButton.innerHTML = '×';
      removeButton.className = 'absolute top-0 right-0 bg-white text-xs px-1 rounded-full';
      removeButton.addEventListener('click', (e) => {
        e.preventDefault();
        this.removeFile(index);
      });
      preview.appendChild(removeButton);

      this.standbyFilesZoneTarget.appendChild(preview);
    });
  }

  removeFile(index) {
    const dt = new DataTransfer(); // input[type="file"] の内容を置き換えるための作業用
    const files = Array.from(this.fileInputTarget.files);

    files.splice(index, 1);
    files.forEach((file) => dt.items.add(file));

    this.fileInputTarget.files = dt.files;
    this.renderPreviews();
  }

  clearPreviews() {
    this.standbyFilesZoneTarget.innerHTML = '';
  }
}
