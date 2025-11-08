export default async function open({ context, attachment }) {
  const { container } = context || {};
  const { sourceUrl, filename } = attachment || {};
  const MAX_BYTES = 16 * 1024; // 16 KiB head preview

  const wrapper = document.createElement('div');
  wrapper.className = 'my-2 relative mb-2 w-full min-w-0 p-4 bg-white rounded-lg shadow-xs';

  // mark wrapper to guard closing when interacting with media controls
  wrapper.setAttribute('data-guard-closing-preview', 'true');

  const header = document.createElement('div');
  header.className = 'flex items-center justify-between mb-2';
  const title = document.createElement('div');
  title.textContent = filename || 'text';
  const download = document.createElement('a');
  download.href = sourceUrl;
  download.textContent = '💾 Download';
  download.className = 'text-blue-600 underline ml-2';
  download.setAttribute('download', '');
  download.setAttribute('target', '_blank');
  header.appendChild(title);
  header.appendChild(download);

  const textarea = document.createElement('textarea');
  textarea.readOnly = true;
  textarea.className = 'w-full h-full font-mono text-sm';
  textarea.value = 'Loading preview...';
  textarea.rows = 20;

  wrapper.appendChild(header);
  wrapper.appendChild(textarea);
  container.appendChild(wrapper);

  function cleanup() {
    if (wrapper.parentNode) wrapper.parentNode.removeChild(wrapper);
  }

  try {
    const res = await fetch(sourceUrl, {
      headers: { Range: `bytes=0-${MAX_BYTES - 1}` },
      credentials: 'same-origin',
    });

    if (res.status === 206 || res.status === 200) {
      const buffer = await res.arrayBuffer();
      const view = new Uint8Array(buffer);
      if (view.some(b => b === 0)) {
        textarea.value = '[Binary file — preview not available]';
        return { cleanup };
      }
      const decoded = new TextDecoder('utf-8', { fatal: false }).decode(buffer);
      const MAX_LINES = 50;
      const lines = decoded.split(/\r?\n/);
      let shownText = decoded;
      if (lines.length > MAX_LINES) {
        shownText = lines.slice(0, MAX_LINES).join('\n') + '\n... (truncated)';
      }
      textarea.value = shownText;
    } else {
      textarea.value = '[Could not fetch preview — use download]';
    }
  } catch (err) {
    textarea.value = '[Preview failed: ' + String(err) + ']';
  }

  return { cleanup };
}
