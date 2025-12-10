import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="pagination"
//
// This controller handles mobile-friendly pagination by allowing users to jump directly
// to a specific page via a numeric input field.
//
// Features:
// - Validates page numbers (must be within 1 to totalPages range)
// - Prevents unnecessary navigation if the entered page is the current page
// - Resets invalid input to the current page number
// - Updates URL query parameter and navigates to the selected page
//
// Used in conjunction with Kaminari pagination views that show a simplified mobile UI
// (prev/next buttons + page input) on small screens.
export default class extends Controller {
  static targets = ["pageInput"]
  static values = {
    totalPages: Number,
    currentPage: Number
  }

  goToPage(event) {
    const pageNumber = parseInt(event.target.value, 10)

    // Validate page number
    if (isNaN(pageNumber) || pageNumber < 1 || pageNumber > this.totalPagesValue) {
      // Reset to current page if invalid
      event.target.value = this.currentPageValue
      return
    }

    // If it's the same page, don't navigate
    if (pageNumber === this.currentPageValue) {
      return
    }

    // Navigate to the selected page
    const url = new URL(window.location.href)
    url.searchParams.set('page', pageNumber)
    window.location.href = url.toString()
  }
}
