import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "textarea", "form", "submitBtn", "confirmModal", "modalTitle", "modalText", "modalIcon"]
  static values = { closed: Boolean, streamUrl: String }

  closeUrl = null
  pendingNavigation = null

  connect() {
    this.scrollToBottom()
    if (this.hasTextareaTarget) {
      this.autoResize()
    }

    // Intercepter les clics sur les liens de navigation si le chat est ouvert
    if (!this.closedValue) {
      this.interceptNavigation()
    }
  }

  disconnect() {
    // Nettoyer les event listeners
    if (this.navigationHandler) {
      document.removeEventListener("click", this.navigationHandler)
    }
  }

  // Intercepter tous les liens de navigation
  interceptNavigation() {
    this.navigationHandler = (event) => {
      const link = event.target.closest("a")
      if (!link) return

      // Ignorer les liens du même chat ou les liens externes
      const href = link.getAttribute("href")
      if (!href || href.startsWith("#") || href.startsWith("javascript:")) return

      // Ignorer le bouton retour (back-btn) - il est géré séparément
      if (link.classList.contains("back-btn")) {
        event.preventDefault()
        this.showNavigationModal(href)
        return
      }

      // Intercepter les liens de la navbar et autres navigations internes
      if (link.closest(".bottom-navbar") || link.closest(".bottom-nav-item")) {
        event.preventDefault()
        this.showNavigationModal(href)
        return
      }
    }

    document.addEventListener("click", this.navigationHandler)
  }

  // Afficher la modale pour navigation
  showNavigationModal(destinationUrl) {
    this.pendingNavigation = destinationUrl
    this.closeUrl = this.element.querySelector("[data-chat-url]")?.dataset.chatUrl

    // Mettre à jour le contenu de la modale
    if (this.hasModalTitleTarget) {
      this.modalTitleTarget.textContent = "Quitter la conversation ?"
    }
    if (this.hasModalTextTarget) {
      this.modalTextTarget.textContent = "En quittant maintenant, la conversation sera terminée et analysée. Tu pourras toujours la consulter ensuite."
    }
    if (this.hasModalIconTarget) {
      this.modalIconTarget.innerHTML = '<i class="fa-solid fa-door-open"></i>'
    }

    this.confirmModalTarget.classList.add("active")
  }

  // Gestion de l'envoi avec Enter (Shift+Enter pour nouvelle ligne)
  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.textareaTarget.value.trim()) {
        this.sendMessage()
      }
    }
  }

  // Auto-resize du textarea
  autoResize() {
    const textarea = this.textareaTarget
    textarea.style.height = "auto"
    textarea.style.height = Math.min(textarea.scrollHeight, 120) + "px"
  }

  // Scroll fluide vers le bas
  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTo({
        top: this.messagesTarget.scrollHeight,
        behavior: 'smooth'
      })
    }
  }

  // Gestion de la soumission du formulaire
  handleSubmit(event) {
    event.preventDefault()
    this.sendMessage()
  }

  // Envoyer le message et gérer le streaming
  async sendMessage() {
    const content = this.textareaTarget.value.trim()
    if (!content) return

    // Désactiver le bouton et le textarea pendant l'envoi
    this.submitBtnTarget.disabled = true
    this.textareaTarget.disabled = true

    // Ajouter le message utilisateur à l'UI
    this.addUserMessage(content)

    // Vider le textarea
    this.textareaTarget.value = ""
    this.autoResize()

    // Créer la bulle de réponse vide avec curseur
    const assistantBubble = this.createAssistantBubble()

    // Scroll vers le bas
    this.scrollToBottom()

    try {
      await this.streamResponse(content, assistantBubble)
    } catch (error) {
      console.error("Streaming error:", error)
      assistantBubble.querySelector(".message-text").textContent = "Désolé, une erreur s'est produite. Veuillez réessayer."
    } finally {
      // Retirer le curseur et réactiver les contrôles
      this.removeCursor(assistantBubble)
      this.submitBtnTarget.disabled = false
      this.textareaTarget.disabled = false
      this.textareaTarget.focus()
    }
  }

  // Ajouter le message utilisateur à l'interface
  addUserMessage(content) {
    const bubble = document.createElement("div")
    bubble.className = "message-bubble user"
    bubble.innerHTML = `
      <div class="message-sender">Vous</div>
      <div class="message-text">${this.escapeHtml(content)}</div>
      <div class="message-time">${this.formatTime(new Date())}</div>
    `
    this.messagesTarget.appendChild(bubble)
  }

  // Créer la bulle de réponse assistant vide
  createAssistantBubble() {
    const bubble = document.createElement("div")
    bubble.className = "message-bubble assistant"
    bubble.innerHTML = `
      <div class="message-sender">Haven (IA)</div>
      <div class="message-text">${this.typingIndicatorHtml()}</div>
      <div class="message-time">${this.formatTime(new Date())}</div>
    `
    this.messagesTarget.appendChild(bubble)
    return bubble
  }

  // HTML pour l'indicateur de frappe (3 points)
  typingIndicatorHtml() {
    return '<span class="typing-indicator"><span class="dot"></span><span class="dot"></span><span class="dot"></span></span>'
  }

  // Retirer le curseur clignotant
  removeCursor(bubble) {
    const cursor = bubble.querySelector(".typing-indicator")
    if (cursor) cursor.remove()
  }

  // Streamer la réponse depuis le serveur
  async streamResponse(content, bubble) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const textElement = bubble.querySelector(".message-text")

    const response = await fetch(this.streamUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "text/event-stream"
      },
      body: JSON.stringify({ message: { content } })
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const reader = response.body.getReader()
    const decoder = new TextDecoder()
    let fullText = ""

    while (true) {
      const { done, value } = await reader.read()
      if (done) break

      const chunk = decoder.decode(value, { stream: true })
      const lines = chunk.split("\n")

      for (const line of lines) {
        if (line.startsWith("data: ")) {
          const data = line.slice(6)

          if (data === "[DONE]") {
            continue
          }

          try {
            const text = JSON.parse(data)
            fullText += text
            // Mettre à jour le texte en gardant l'indicateur de frappe
            textElement.innerHTML = this.escapeHtml(fullText) + this.typingIndicatorHtml()
            this.scrollToBottom()
          } catch (e) {
            // Ignorer les erreurs de parsing
          }
        }
      }
    }

    // Texte final sans curseur
    textElement.textContent = fullText
  }

  // Échapper le HTML pour éviter XSS
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  // Formater l'heure
  formatTime(date) {
    const day = date.getDate().toString().padStart(2, "0")
    const month = date.toLocaleString("fr-FR", { month: "short" })
    const hours = date.getHours().toString().padStart(2, "0")
    const minutes = date.getMinutes().toString().padStart(2, "0")
    return `${day} ${month} ${hours}:${minutes}`
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
    this.pendingNavigation = null

    // Restaurer le contenu par défaut de la modale
    if (this.hasModalTitleTarget) {
      this.modalTitleTarget.textContent = "Terminer cette conversation ?"
    }
    if (this.hasModalTextTarget) {
      this.modalTextTarget.textContent = "Tu pourras toujours la consulter, mais tu ne pourras plus envoyer de messages."
    }
    if (this.hasModalIconTarget) {
      this.modalIconTarget.innerHTML = '<i class="fa-solid fa-check-circle"></i>'
    }
  }

  // Exécuter la fermeture
  executeClose() {
    if (this.closeUrl) {
      // Si on a une navigation en attente, on doit fermer puis rediriger
      if (this.pendingNavigation) {
        this.closeAndNavigate()
        return
      }

      // Sinon, comportement standard : fermer et laisser le serveur rediriger
      const form = document.createElement("form")
      form.method = "POST"
      form.action = this.closeUrl

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

  // Fermer le chat puis naviguer vers la destination
  async closeAndNavigate() {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    try {
      await fetch(this.closeUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        }
      })

      // Que la requête réussisse ou non, on navigue vers la destination
      window.location.href = this.pendingNavigation
    } catch {
      // En cas d'erreur, naviguer quand même
      window.location.href = this.pendingNavigation
    }
  }
}
