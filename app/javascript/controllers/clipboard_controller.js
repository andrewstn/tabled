import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "source", "button" ]

  async copy() {
    await navigator.clipboard.writeText(this.sourceTarget.value)
    this.buttonTarget.textContent = "Copied"
  }
}
