// LiveView hook for the DeadSimpleCms markdown editor.
//
// Usage in assets/js/app.js:
//
//     import EasyMDEHook from "./easymde_hook"
//     let liveSocket = new LiveSocket("/live", Socket, {hooks: {EasyMDE: EasyMDEHook, ...}})
import EasyMDE from "./easymde.min.js"

const EasyMDEHook = {
  mounted() {
    if (this.editor) return

    this.targetInput = document.getElementById(this.el.dataset.targetInputId)
    if (!this.targetInput) return

    this.editorElement = document.createElement("textarea")
    this.editorElement.value = this.targetInput.value || this.el.dataset.initialValue || ""
    this.el.appendChild(this.editorElement)

    this.editor = new EasyMDE({
      element: this.editorElement,
      spellChecker: false,
      status: false,
      autoDownloadFontAwesome: true,
      forceSync: true,
      autosave: { enabled: false },
      toolbar: ["bold", "italic", "heading", "|", "quote", "unordered-list", "ordered-list", "|", "link", "|", "guide"]
    })

    this.codemirror = this.editor.codemirror

    this.onChange = () => {
      if (!this.targetInput) return
      this.targetInput.value = this.editor.value()
      this.targetInput.dispatchEvent(new Event("input", { bubbles: true }))
    }

    this.codemirror.on("change", this.onChange)

    // An editor that starts inside a closed <details> is drawn at zero size, so redraw it when opened.
    this.details = this.el.closest("details")
    this.onToggle = () => {
      if (this.details.open && this.codemirror) this.codemirror.refresh()
    }
    if (this.details) this.details.addEventListener("toggle", this.onToggle)
  },

  destroyed() {
    if (this.details && this.onToggle) {
      this.details.removeEventListener("toggle", this.onToggle)
    }

    if (this.codemirror && this.onChange) {
      this.codemirror.off("change", this.onChange)
    }

    if (this.editor) {
      this.editor.toTextArea()
    }

    this.editor = null
    this.codemirror = null
    this.editorElement = null
    this.targetInput = null
    this.onChange = null
    this.details = null
    this.onToggle = null
  }
}

export default EasyMDEHook
