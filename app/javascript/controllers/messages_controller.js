import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['preview', 'modal', 'modalBody']

  _generateMapContainer(mapId) {
    const content = document.createElement('div');
    content.id = mapId;
    content.style.width = "800px";
    content.style.height = "800px";
    content.className = "object-contain max-h-full max-w-full mx-auto my-2";
    content.setAttribute('data-guard-closing-preview', 'true');
    return content;
  }

  _activateMapContent(mapId, gpxUrl){
    const map = L.map(mapId).setView([35.6812, 139.7671], 13); // 東京駅付近

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map);

    new L.GPX(gpxUrl, {
      async: true,
      markers: {
        startIcon: 'leaflet-gpx/icons/pin-icon-start.png',
        endIcon: 'leaflet-gpx/icons/pin-icon-end.png',
        wptIcons: {}
      },
      marker_options: {
        iconSize: [24, 32],
        iconAnchor: [12, 32],
      }
    }).on('loaded', function(e) {
      map.fitBounds(e.target.getBounds());
    }).addTo(map);
  }

  changePreview(evt) {
    evt.preventDefault();

    if (this.isDisplayed(this.previewTarget)) {
      this.clearPreview();

      // WIP:
      if (evt.currentTarget.dataset["contentType"] != "application/xml" || !evt.currentTarget.dataset["filename"].match("\.gpx$") ) {
        const content = evt.currentTarget.querySelector('img, video').cloneNode(true);
        this.previewTarget.appendChild(content);
      } else {
        const content = this._generateMapContainer("map");
        this.previewTarget.appendChild(content);
        const map = this._activateMapContent(content.id, evt.currentTarget.dataset["sourceUrl"]);
        map.invalidateSize();
      }
    } else {
      this.clearModal();
      this.openModal();
      if (evt.currentTarget.dataset["contentType"] != "application/xml" || !evt.currentTarget.dataset["filename"].match("\.gpx$") ) {
        const content = evt.currentTarget.querySelector('img, video').cloneNode(true);
        this.modalBodyTarget.appendChild(content);
      } else {
        const content = this._generateMapContainer("map");
        this.modalBodyTarget.appendChild(content);
        const map = this._activateMapContent(content.id, evt.currentTarget.dataset["sourceUrl"]);
        map.invalidateSize();
      }
    }
  }

  isDisplayed(elem) {
    return elem.offsetParent !== null
  }

  handlerClearPreview(evt) {
    // WIP:
    if (evt.currentTarget.dataset["guardClosingPreview"]) {
      console.log("guard by event currentTarget");
      return;
    }
    // WIP:
    if (evt.target.dataset["guardClosingPreview"]) {
      console.log("guard by event target");
      return;
    }

    this.clearPreview();
  }

  handlerCloseModal(evt) {
    // WIP:
    if (evt.currentTarget.dataset["guardClosingPreview"]) {
      console.log("guard by event currentTarget");
      return;
    }
    // WIP:
    if (evt.target.dataset["guardClosingPreview"]) {
      console.log("guard by event target");
      return;
    }

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
