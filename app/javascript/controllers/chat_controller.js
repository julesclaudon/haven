import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "textarea", "form", "submitBtn", "confirmModal"]
  static values = { closed: Boolean }

  closeUrl = null

  connect() {
    this.scrollToBottom()
    if (this.hasTextareaTarget) {
      this.autoResize()
    }
  }

  // Gestion de l'envoi avec Enter (Shift+Enter pour nouvelle ligne)
  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.textareaTarget.value.trim()) {
        this.formTarget.requestSubmit()
      }
    }
  }

  // Auto-resize du textarea
  autoResize() {
    const textarea = this.textareaTarget
    textarea.style.height = "auto"
    textarea.style.height = Math.min(textarea.scrollHeight, 120) + "px"
  }

  // Scroll vers le bas
  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  // Gestion de la soumission du formulaire
  handleSubmit(event) {
    const content = this.textareaTarget.value.trim()
    if (!content) {
      event.preventDefault()
      return
    }

    // Désactiver le bouton pendant l'envoi
    this.submitBtnTarget.disabled = true
  }

  // Afficher la modale de confirmation
  confirmClose(event) {
    this.closeUrl = event.currentTarget.dataset.chatUrl
    this.confirmModalTarget.classList.add("active")
  }

  // Annuler la fermeture
  cancelClose() {
    this.confirmModalTarget.classList.remove("active")
    this.closeUrl = null
  }

  // Exécuter la fermeture
  executeClose() {
    if (this.closeUrl) {
      // Créer un formulaire pour POST
      const form = document.createElement("form")
      form.method = "POST"
      form.action = this.closeUrl

      // Ajouter le token CSRF
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      if (csrfToken) {
        const csrfInput = document.createElement("input")
        csrfInput.type = "hidden"
        csrfInput.name = "authenticity_token"
        csrfInput.value = csrfToken
        form.appendChild(csrfInput)
      }

      document.body.appendChild(form)
      form.submit()
    }
  }
}
