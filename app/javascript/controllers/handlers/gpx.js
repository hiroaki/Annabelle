export default function open({ context, attachment }) {
  const { container } = context || {};
  const { sourceUrl } = attachment || {};

  // create map container locally so handler does not depend on controller API
  const mapId = `map-${Date.now()}`;
  const el = document.createElement('div');
  el.id = mapId;
  el.style.width = '800px';
  el.style.height = '800px';
  el.className = 'object-contain max-h-full max-w-full mx-auto p-4';
  el.setAttribute('data-guard-closing-preview', 'true');
  container.appendChild(el);

  // initialize Leaflet map (assumes global L is available as in the app)
  const map = L.map(el.id).setView([35.6812, 139.7671], 13);

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors',
  }).addTo(map);

  const gpx = new L.GPX(sourceUrl, {
    async: true,
  }).on('loaded', function (e) {
    map.fitBounds(e.target.getBounds());
  }).addTo(map);

  if (typeof map.invalidateSize === 'function') map.invalidateSize();

  return {
    cleanup() {
      if (gpx && typeof gpx.clear === 'function') {
        gpx.clear();
      }
      if (map && typeof map.remove === 'function') map.remove();
      if (el.parentNode) el.parentNode.removeChild(el);
    },
  };
}
