import { Controller } from "@hotwired/stimulus";

/*
  metadata_fetcher_controller

  Purpose:
  - Ensure attachment metadata (latitude/longitude) is available before the
    preview action runs. Stimulus will call multiple actions declared on the
    same element in order, but it does not await Promises returned by an
    action. To guarantee ordering when the first action performs async work,
    this controller performs a stop->fetch->re-dispatch pattern.

  Behavior:
  - If metadata is missing, `prepare` calls `evt.stopImmediatePropagation()` and
    `evt.preventDefault()` to stop subsequent same-element listeners from
    running immediately.
  - It then fetches metadata from the server and updates Stimulus values.
  - Finally it re-dispatches the original event as a `CustomEvent` with
    `detail.metadataFetched = true` so that this controller knows not to
    intercept the re-dispatched event (prevents infinite loops) and allows
    the preview controller to run with up-to-date data.

  Notes:
  - This is intentionally compact: keep the logic here focused and easy to
    reason about. If you prefer a different flow (direct-controller call or
    a dedicated "metadata-ready" custom event), it's straightforward to
    refactor to that approach.
*/

export default class extends Controller {
  static values = {
    attachmentId: String,
    latitude: String,
    longitude: String,
    metadataUrl: String
  }

  async prepare(evt) {
    // If this event was already processed by us (re-dispatched), let it bubble to the next controller
    if (evt.detail && evt.detail.metadataFetched) return;

    // If we already have location data, or no attachment ID, we don't need to fetch.
    // However, if we don't stop propagation, the next action (messages#changePreview) runs immediately.
    // If we have data, we can just let it run.
    if ((this.hasLatitudeValue && this.hasLongitudeValue) || !this.hasAttachmentIdValue) {
      return;
    }

    // If the server didn't render a metadata URL, consider metadata absent
    // and don't attempt to fetch. Let the preview action run immediately.
    if (!this.hasMetadataUrlValue) {
      return;
    }

    // Stop the event from reaching the next controller immediately
    evt.stopImmediatePropagation();
    evt.preventDefault();

    try {
      // Use server-provided metadata URL (always present here).
      const response = await fetch(this.metadataUrlValue, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      });

      if (response.ok) {
        const meta = await response.json();
        if (meta.latitude && meta.longitude) {
          this.latitudeValue = meta.latitude;
          this.longitudeValue = meta.longitude;
        }
      }
    } catch (e) {
      console.warn('Failed to fetch attachment metadata', e);
    } finally {
      // Re-dispatch the event so the next controller can handle it
      // We add a flag in 'detail' to avoid infinite loop
      const newEvent = new CustomEvent(evt.type, {
        bubbles: true,
        cancelable: true,
        detail: { metadataFetched: true }
      });
      evt.target.dispatchEvent(newEvent);
    }
  }
}
