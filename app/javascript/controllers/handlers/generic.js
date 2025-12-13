export default function open({ context, attachment }) {
  const { container } = context || {};
  const { sourceUrl, filename, contentType } = attachment || {};
  const wrapper = document.createElement('div');
  wrapper.className = 'relative w-full min-w-0 p-4 bg-white rounded-lg shadow-2xs';

  if (!sourceUrl) {
    container.appendChild(wrapper);
    return {
      cleanup() {
        if (wrapper.parentNode) wrapper.parentNode.removeChild(wrapper);
      }
    };
  }

  if (filename) {
    const nameEl = document.createElement('div');
    nameEl.className = 'text-xs text-gray-700 mb-1';
    nameEl.textContent = filename;
    wrapper.appendChild(nameEl);
  }

  if (contentType) {
    const typeEl = document.createElement('div');
    typeEl.className = 'text-xs text-gray-500 mb-1';
    typeEl.textContent = contentType;
    wrapper.appendChild(typeEl);
  }

  const link = document.createElement('a');
  link.href = sourceUrl;
  link.textContent = '💾 Download';
  link.className = 'text-blue-600 underline';
  link.setAttribute('download', '');
  wrapper.appendChild(link);
  container.appendChild(wrapper);

  return {
    cleanup() {
      if (wrapper.parentNode) wrapper.parentNode.removeChild(wrapper);
    }
  };
}
