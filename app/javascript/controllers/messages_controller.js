import { Controller } from "@hotwired/stimulus";

import imageHandler from "controllers/handlers/image";
import videoHandler from "controllers/handlers/video";
import gpxHandler from "controllers/handlers/gpx";
import genericHandler from "controllers/handlers/generic";
import textHandler from "controllers/handlers/text";

const REGISTRY = [
  { match: (ct) => /^image\//.test(ct), handler: imageHandler },
  { match: (ct) => /^video\//.test(ct), handler: videoHandler },
  { match: (ct, fn) => ct === 'application/xml' && /\.gpx$/i.test(fn), handler: gpxHandler },
  { match: (ct) => /^text\//.test(ct), handler: textHandler },
  { match: () => true, handler: genericHandler }
]

function findHandler(contentType, filename) {
  const entry = REGISTRY.find(e => e.match(contentType, filename));
  return entry ? entry.handler : genericHandler;
}

export default class extends Controller {
  static targets = ['preview', 'modal', 'modalBody'];

  initialize() {
    // container(Element) -> instance ({ cleanup: fn })
    this._previewInstances = new WeakMap();
  }

  disconnect() {
    // ensure cleanup when controller is torn down
    this._cleanupFor(this.previewTarget);
    this._cleanupFor(this.modalBodyTarget);
  }

  async changePreview(evt) {
    evt.preventDefault();

    const elem = evt.currentTarget;
    // The metadata-fetcher controller ensures these values are populated if available
    const latitude = elem.dataset['metadataFetcherLatitudeValue'];
    const longitude = elem.dataset['metadataFetcherLongitudeValue'];

    const data = {
      sourceUrl: elem.dataset['sourceUrl'],
      filename: elem.dataset['filename'],
      contentType: elem.dataset['contentType'],
      latitude: latitude,
      longitude: longitude,
    };

    const isPreviewDisplayed = this.isDisplayed(this.previewTarget);
    const display = isPreviewDisplayed ? 'preview' : 'modal';
    const container = isPreviewDisplayed ? this.previewTarget : this.modalBodyTarget;

    // cleanup existing preview for the chosen container BEFORE rendering new content
    this._cleanupFor(container);

    if (!isPreviewDisplayed) {
      this.clearModal();
      this.openModal();
    } else {
      this.clearPreview();
    }

    // extract a preview image from the thumbnail element and pass a simple string
    // to handlers to avoid handing over DOM nodes (safer, lower coupling)
    let previewUrl = null;
    if (typeof elem.querySelector === 'function') {
      const thumbVideo = elem.querySelector('video');
      if (thumbVideo) previewUrl = thumbVideo.getAttribute('poster');
      if (!previewUrl) {
        const thumbImg = elem.querySelector('img');
        if (thumbImg) previewUrl = thumbImg.dataset && thumbImg.dataset.src ? thumbImg.dataset.src : thumbImg.src;
      }
    }

    const context = { container, display, isPreview: isPreviewDisplayed };
    const attachment = { ...data, previewUrl };

    const handler = findHandler(data.contentType, data.filename);
    try {
      const result = await handler({ context, attachment });
      const instance = (typeof result === 'function') ? { cleanup: result } : (result || {});
      if (instance && typeof instance.cleanup === 'function') {
        this._previewInstances.set(container, instance);
      }
    } catch (err) {
      console.error('preview handler error', err);
      // fallback: clone thumbnail img/video if present
      const content = elem.querySelector('img, video');
      if (content) container.appendChild(content.cloneNode(true));
    }
  }

  isDisplayed(elem) {
    return elem.offsetParent !== null;
  }

  handlerClearPreview(evt) {
    // If any element in the event path has data-guard-closing-preview, do not close
    try {
      if (evt.currentTarget && evt.currentTarget.dataset && evt.currentTarget.dataset['guardClosingPreview']) return;
      const path = evt.composedPath ? evt.composedPath() : (evt.path || []);
      if (path && path.some(el => el && el.dataset && el.dataset['guardClosingPreview'])) return;
    } catch (e) {
      // fallback to previous behavior
      if (evt.target && evt.target.dataset && evt.target.dataset['guardClosingPreview']) return;
    }

    this.clearPreview();
  }

  handlerCloseModal(evt) {
    // If any element in the event path has data-guard-closing-preview, do not close
    try {
      if (evt.currentTarget && evt.currentTarget.dataset && evt.currentTarget.dataset['guardClosingPreview']) return;
      const path = evt.composedPath ? evt.composedPath() : (evt.path || []);
      if (path && path.some(el => el && el.dataset && el.dataset['guardClosingPreview'])) return;
    } catch (e) {
      if (evt.target && evt.target.dataset && evt.target.dataset['guardClosingPreview']) return;
    }

    this.closeModal();
  }

  _cleanupFor(container) {
    if (!container) return;
    const prev = this._previewInstances.get(container);
    if (prev) {
      try { if (typeof prev.cleanup === 'function') prev.cleanup(); } catch (e) { console.error(e); }
      this._previewInstances.delete(container);
    }
    // ensure DOM is cleared as a last resort
    container.innerHTML = '';
  }

  clearPreview() {
    this._cleanupFor(this.previewTarget);
  }

  clearModal() {
    this._cleanupFor(this.modalBodyTarget);
  }

  openModal() {
    this.modalTarget.classList.remove('hidden');
  }

  closeModal() {
    this.modalTarget.classList.add('hidden');
  }
}
