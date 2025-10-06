import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const width = this.element.dataset.width
    if (width) {
      this.element.style.width = width + "%"
    }
  }
}
