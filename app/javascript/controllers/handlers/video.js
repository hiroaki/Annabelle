export default function open({ context, attachment }) {
  const { container, display } = context || {};
  const { sourceUrl, previewUrl } = attachment || {};
  const wrapper = document.createElement('div');
  wrapper.className = 'relative w-full h-full';

  const video = document.createElement('video');
  video.controls = true;
  video.muted = true;
  video.preload = 'none';
  video.className = 'lazyload w-full object-contain max-h-full max-w-full';

  // Prefer poster URL passed from controller if provided
  if (previewUrl) video.setAttribute('poster', previewUrl);

  // Set the src in the modal; for sidebar preview, set the src too but only
  // preload metadata so controls are enabled while avoiding a full download.
  const isModal = display === 'modal';
  if (sourceUrl) {
    if (isModal) {
      video.src = sourceUrl;
    } else {
      // For the sidebar preview: request only metadata so the browser
      // enables controls (duration, seeking UI) without downloading
      // the whole file immediately.
      video.preload = 'metadata';
      video.src = sourceUrl;
    }
  }

  wrapper.appendChild(video);

  // transparent overlay to match previous layout; do not block pointer events
  const overlay = document.createElement('div');
  overlay.style.position = 'absolute';
  overlay.style.top = '0';
  overlay.style.left = '0';
  overlay.style.width = '100%';
  overlay.style.height = '100%';
  overlay.style.pointerEvents = 'none';
  wrapper.appendChild(overlay);

  // mark wrapper to guard closing when interacting with media controls
  wrapper.setAttribute('data-guard-closing-preview', 'true');

  container.appendChild(wrapper);

  return {
    cleanup() {
      if (video) {
        video.pause();
        video.removeAttribute('src');
      }
      if (wrapper.parentNode) wrapper.parentNode.removeChild(wrapper);
    }
  };
}
