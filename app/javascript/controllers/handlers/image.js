export default function open({ context, attachment }) {
  const { container } = context || {};
  const { sourceUrl } = attachment || {};
  const img = document.createElement('img');
  img.className = 'lazyload object-contain max-h-full max-w-full mx-auto';
  // set dataset for existing lazyload behavior, but also set src as fallback
  if (sourceUrl) {
    img.dataset.src = sourceUrl;
    img.src = sourceUrl;
  }
  container.appendChild(img);

  return {
    cleanup() {
      if (img.parentNode) img.parentNode.removeChild(img);
    }
  };
}
