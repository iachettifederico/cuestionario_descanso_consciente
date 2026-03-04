import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]

  open() {
    this.overlayTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  closeOnBackdrop(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }
}
