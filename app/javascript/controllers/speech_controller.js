import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button", "form"]
  static values = {
    autoSubmit: { type: Boolean, default: true },
    language: { type: String, default: "fr-FR" }
  }

  recognition = null
  isListening = false

  connect() {
    console.log("Speech controller connected")
    if (!this.isSupported()) {
      console.log("Speech API not supported")
      this.hideButton()
      return
    }
    console.log("Setting up speech recognition")
    this.setupRecognition()
  }

  disconnect() {
    if (this.recognition && this.isListening) {
      this.recognition.stop()
    }
  }

  isSupported() {
    return 'webkitSpeechRecognition' in window || 'SpeechRecognition' in window
  }

  hideButton() {
    if (this.hasButtonTarget) {
      this.buttonTarget.style.display = 'none'
    }
  }

  setupRecognition() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
    this.recognition = new SpeechRecognition()
    this.recognition.lang = this.languageValue
    this.recognition.continuous = false
    this.recognition.interimResults = false

    this.recognition.onstart = () => {
      this.isListening = true
      this.buttonTarget.classList.add('listening')
    }

    this.recognition.onresult = (event) => {
      const transcript = event.results[0][0].transcript
      this.insertText(transcript)

      if (this.autoSubmitValue) {
        this.submitForm()
      }
    }

    this.recognition.onerror = (event) => {
      console.error('Speech recognition error:', event.error)

      // Messages d'erreur plus explicites
      switch(event.error) {
        case 'not-allowed':
          alert("Accès au microphone refusé. Autorise l'accès dans les paramètres du navigateur.")
          break
        case 'no-speech':
          console.log("Aucune parole détectée")
          break
        case 'network':
          alert("Erreur réseau. La reconnaissance vocale nécessite une connexion internet.")
          break
        case 'aborted':
          console.log("Reconnaissance annulée")
          break
      }

      this.stopListening()
    }

    this.recognition.onend = () => {
      this.stopListening()
    }
  }

  toggle() {
    console.log("Toggle called, isListening:", this.isListening)
    if (this.isListening) {
      this.recognition.stop()
    } else {
      this.recognition.start()
    }
  }

  stopListening() {
    this.isListening = false
    this.buttonTarget.classList.remove('listening')
  }

  insertText(text) {
    if (this.hasInputTarget) {
      // Pour textarea ou input
      const input = this.inputTarget
      const currentValue = input.value.trim()

      if (currentValue) {
        input.value = currentValue + ' ' + text
      } else {
        input.value = text
      }

      // Trigger input event pour auto-resize si besoin
      input.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }

  submitForm() {
    // Petit délai pour que l'utilisateur voie le texte avant l'envoi
    setTimeout(() => {
      if (this.hasFormTarget) {
        this.formTarget.requestSubmit()
      } else {
        // Chercher le formulaire parent
        const form = this.element.closest('form') || this.element.querySelector('form')
        if (form) {
          form.requestSubmit()
        }
      }
    }, 300)
  }
}
