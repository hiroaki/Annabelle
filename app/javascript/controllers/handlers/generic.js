export default function open({ context, attachment }) {
  const { container } = context || {};
  const { sourceUrl, filename, contentType } = attachment || {};
  const wrapper = document.createElement('div');
  wrapper.className = 'my-2 h-40 w-40 bg-gray-200 flex flex-col items-center justify-center text-sm text-gray-700 p-2';

  if (!sourceUrl) {
    container.appendChild(wrapper);
    return {
      cleanup() {
        if (wrapper.parentNode) wrapper.parentNode.removeChild(wrapper);
      },
    };
  }

  // Display filename/contentType when available, and provide a download link as a fallback
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
  link.textContent = 'Download';
  link.className = 'text-blue-600 underline';
  link.setAttribute('download', '');
  wrapper.appendChild(link);
  container.appendChild(wrapper);

  return {
    cleanup() {
      if (wrapper.parentNode) wrapper.parentNode.removeChild(wrapper);
    },
  };
}
