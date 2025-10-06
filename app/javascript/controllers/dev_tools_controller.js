import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "toggle"]

  toggle() {
    if (this.contentTarget.style.display === "none") {
      this.contentTarget.style.display = "block"
      this.toggleTarget.textContent = "−"
    } else {
      this.contentTarget.style.display = "none"
      this.toggleTarget.textContent = "+"
    }
  }
}
