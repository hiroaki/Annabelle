export default function open({ context, attachment }) {
  const { container } = context || {};
  const { sourceUrl, latitude, longitude } = attachment || {};

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

  if (latitude && longitude) {
    const meta = document.querySelector('meta[name="current-user-show-location-preview"]');
    const showLocation = meta && meta.content === 'true';

    if (showLocation) {
      const mapContainer = document.createElement('div');
      mapContainer.className = 'w-full h-64 mt-4';

      const iframe = document.createElement('iframe');
      iframe.width = '100%';
      iframe.height = '100%';
      iframe.frameBorder = '0';
      iframe.scrolling = 'no';
      iframe.marginHeight = '0';
      iframe.marginWidth = '0';

      // OpenStreetMap Embed
      const lat = parseFloat(latitude);
      const lon = parseFloat(longitude);
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

  container.appendChild(wrapper);

  return {
    cleanup() {
      if (wrapper.parentNode) wrapper.parentNode.removeChild(wrapper);
    }
  };
}
