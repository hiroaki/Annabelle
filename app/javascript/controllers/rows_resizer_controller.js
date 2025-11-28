import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rows-resizer"
//
// This controller dynamically adjusts the number of rows in a textarea based on:
// 1. Screen size (mobile vs desktop using Tailwind's lg breakpoint)
// 2. Focus state (expanded when focused, compact when blurred)
//
// Key technique: Uses a "probe element" with Tailwind's responsive classes (hidden lg:block)
// to detect the lg breakpoint without hardcoding pixel values. This ensures the JS logic
// stays synchronized with Tailwind's configuration, even if breakpoint values change.
//
// Behavior:
// - Desktop (lg and above): Always shows `initialRows` (typically 3)
// - Mobile (below lg):
//   - Unfocused: Shows `compactRows` (default: 1)
//   - Focused: Shows `expandedRows` (default: 3)
export default class extends Controller {
  static values = {
    compactRows: { type: Number, default: 1 },
    expandedRows: { type: Number, default: 3 },
  }

  connect() {
    this.initialRows = parseInt(this.element.getAttribute("rows"), 10)
    if (Number.isNaN(this.initialRows)) {
      this.initialRows = this.expandedRowsValue
    }

    // Create a probe element that uses Tailwind's responsive classes to detect lg breakpoint
    this.probeEl = document.createElement("div")
    this.probeEl.setAttribute("aria-hidden", "true")
    this.probeEl.className = "hidden lg:block"
    // Keep it non-intrusive
    this.probeEl.style.position = "absolute"
    this.probeEl.style.width = "0px"
    this.probeEl.style.height = "0px"
    this.probeEl.style.overflow = "hidden"
    this.probeEl.style.pointerEvents = "none"
    document.body.appendChild(this.probeEl)

    this.handleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.handleResize)

    // Set initial rows based on breakpoint
    if (this.isMobile()) {
      this.setRows(this.compactRowsValue)
    } else {
      this.setRows(this.initialRows)
    }
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize)
    if (this.probeEl && this.probeEl.parentNode) {
      this.probeEl.parentNode.removeChild(this.probeEl)
    }
  }

  expand() {
    if (this.isMobile()) this.setRows(this.expandedRowsValue)
  }

  collapse() {
    if (this.isMobile()) this.setRows(this.compactRowsValue)
  }

  handleResize() {
    if (!this.isMobile()) {
      this.setRows(this.initialRows)
    } else if (document.activeElement === this.element) {
      this.setRows(this.expandedRowsValue)
    } else {
      this.setRows(this.compactRowsValue)
    }
  }

  isMobile() {
    // When the probe displays as block, we're at lg or above
    const display = this.probeEl ? window.getComputedStyle(this.probeEl).display : "none"
    const isLgUp = display !== "none"
    return !isLgUp
  }

  setRows(n) {
    if (this.element && this.element.rows !== n) {
      this.element.rows = n
    }
  }
}
