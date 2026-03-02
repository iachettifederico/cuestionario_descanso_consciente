// app/javascript/controllers/diary_controller.js
// Maneja actualizaciones de ratings via fetch AJAX.
// EXCEPCIÓN justificada al Hotwire-first guideline: los ratings se guardan
// instantáneamente al hacer click, lo que requiere PATCH al servidor sin submit.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    day: Number,
    updateRatingUrl: String
  }

  async setRating(event) {
    const tipo  = event.params.tipo
    const valor = parseInt(event.params.valor)

    this.updateRatingUI(tipo, valor)

    try {
      const response = await fetch(this.updateRatingUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ tipo, valor })
      })

      if (!response.ok) {
        console.error("Error guardando rating")
      }
    } catch (e) {
      console.error("Error de red:", e)
    }
  }

  updateRatingUI(tipo, valor) {
    const allDots = this.element.querySelectorAll(`[data-diary-tipo-param="${tipo}"]`)

    allDots.forEach(dot => {
      const dotValor = parseInt(dot.dataset.diaryValorParam)
      const level    = dotValor <= 2 ? "low" : dotValor === 3 ? "mid" : "high"

      if (dotValor === valor) {
        dot.dataset.selected = "true"
        dot.dataset.level    = level
      } else {
        dot.dataset.selected = "false"
        delete dot.dataset.level
      }
    })
  }
}
