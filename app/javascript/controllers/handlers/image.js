export default function open({ context, attachment }) {
  const { container } = context || {};
  const { sourceUrl, latitude, longitude } = attachment || {};

  // Pre-parse coordinates so validation is applied consistently and early.
  // Parsing early ensures we never rely on truthiness checks that can
  // misinterpret numeric strings like "0" or accept empty strings.
  const parsedLat = parseFloat(latitude);
  const parsedLon = parseFloat(longitude);

  const wrapper = document.createElement('div');
  wrapper.className = 'flex flex-col items-center w-full h-full';

  const img = document.createElement('img');
  img.className = 'lazyload object-contain max-h-full max-w-full mx-auto';
  // set dataset for existing lazyload behavior, but also set src as fallback
  if (sourceUrl) {
    img.dataset.src = sourceUrl;
    img.src = sourceUrl;
  }
  wrapper.appendChild(img);

  if (Number.isFinite(parsedLat) && Number.isFinite(parsedLon)) {
    const lat = parsedLat;
    const lon = parsedLon;

    const validLat = lat >= -90 && lat <= 90;
    const validLon = lon >= -180 && lon <= 180;

    if (validLat && validLon) {
      const meta = document.querySelector('meta[name="current-user-show-location-preview"]');
      const showLocation = meta && meta.content === 'true';

      if (showLocation) {
        const mapContainer = document.createElement('div');
        mapContainer.className = 'w-full h-64 mt-4';

        const iframe = document.createElement('iframe');
        iframe.width = '100%';
        iframe.height = '100%';
        // Use modern CSS for overflow and spacing instead of deprecated attributes
        iframe.style.overflow = 'hidden';
        // OpenStreetMap Embed
        const delta = 0.005; // Approx 500m-1km depending on latitude
        const bbox = `${lon - delta},${lat - delta},${lon + delta},${lat + delta}`;

        iframe.src = `https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat},${lon}`;
        iframe.style.border = '1px solid #ccc';

        mapContainer.appendChild(iframe);
        wrapper.appendChild(mapContainer);

        const link = document.createElement('a');
        link.href = `https://www.openstreetmap.org/?mlat=${lat}&mlon=${lon}#map=16/${lat}/${lon}`;
        link.target = '_blank';
        link.className = 'text-blue-500 underline text-sm mt-1 block text-center';
        link.innerText = 'View larger map';
        wrapper.appendChild(link);
      }
    }
  }

  container.appendChild(wrapper);

  return {
    cleanup() {
      if (wrapper.parentNode) wrapper.parentNode.removeChild(wrapper);
    }
  };
}
