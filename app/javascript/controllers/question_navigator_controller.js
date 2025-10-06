import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["question", "counter", "nextButton", "prevButton"]
  static values = { current: Number, total: Number }

  connect() {
    this.currentValue = 0
    this.updateDisplay()
  }

  next() {
    if (this.currentValue < this.totalValue - 1) {
      this.currentValue++
      this.updateDisplay()
    }
  }

  previous() {
    if (this.currentValue > 0) {
      this.currentValue--
      this.updateDisplay()
    }
  }

  updateDisplay() {
    // Ocultar todas las preguntas
    this.questionTargets.forEach((question, index) => {
      if (index === this.currentValue) {
        question.classList.remove("hidden")
        question.classList.add("block")
      } else {
        question.classList.add("hidden")
        question.classList.remove("block")
      }
    })

    // Actualizar contador
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `Pregunta ${this.currentValue + 1} de ${this.totalValue}`
    }

    // Actualizar botones
    if (this.hasPrevButtonTarget) {
      if (this.currentValue === 0) {
        this.prevButtonTarget.classList.add("invisible")
      } else {
        this.prevButtonTarget.classList.remove("invisible")
      }
    }

    if (this.hasNextButtonTarget) {
      if (this.currentValue === this.totalValue - 1) {
        this.nextButtonTarget.classList.add("hidden")
      } else {
        this.nextButtonTarget.classList.remove("hidden")
      }
    }
  }

  // Función para avanzar automáticamente cuando se selecciona una respuesta
  answerSelected(event) {
    // Esperar un momento para que se vea la selección
    setTimeout(() => {
      if (this.currentValue < this.totalValue - 1) {
        this.next()
      }
    }, 300)
  }
}