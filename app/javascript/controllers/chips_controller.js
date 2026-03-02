// app/javascript/controllers/chips_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  select(event) {
    const clicked = event.currentTarget

    this.element.querySelectorAll(".tipo-chip").forEach(chip => {
      chip.classList.remove("active")
      const radio = chip.querySelector("input[type='radio']")
      if (radio) radio.checked = false
    })

    clicked.classList.add("active")
    const radio = clicked.querySelector("input[type='radio']")
    if (radio) radio.checked = true
  }
}
