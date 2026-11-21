import { Controller } from "@hotwired/stimulus"

let clerkInitialization

async function initializeClerk() {
  if (!window.Clerk && document.readyState !== "complete") {
    await new Promise(resolve => window.addEventListener("load", resolve, { once: true }))
  }

  const clerk = window.Clerk
  const ClerkUI = window.__internal_ClerkUICtor
  if (!clerk || !ClerkUI) throw new Error("Clerk SDK was not loaded")

  await clerk.load({ ui: { ClerkUI } })
  return clerk
}

export default class extends Controller {
  static targets = ["logout", "form", "error"]

  async connect() {
    try {
      clerkInitialization ??= initializeClerk()
      this.clerk = await clerkInitialization
      this.errorTarget.hidden = true
      if (this.hasLogoutTarget) this.logoutTarget.disabled = false
      if (this.hasFormTarget) this.mountForm()
    } catch {
      this.showError("Clerk could not load. Try refreshing the page.")
    }
  }

  disconnect() {
    this.unmount()
  }

  mountForm() {
    const form = this.formTarget
    const { mode, signInUrl, signUpUrl, returnUrl } = form.dataset
    if (this.clerk.isSignedIn) {
      window.location.replace(returnUrl)
      return
    }

    const options = { routing: "hash", signInUrl, signUpUrl, forceRedirectUrl: returnUrl }
    if (mode === "sign-up") {
      this.clerk.mountSignUp(form, options)
    } else {
      this.clerk.mountSignIn(form, options)
    }
    this.mountedForm = form
  }

  unmount() {
    if (!this.mountedForm) return

    if (this.mountedForm.dataset.mode === "sign-up") {
      this.clerk.unmountSignUp(this.mountedForm)
    } else {
      this.clerk.unmountSignIn(this.mountedForm)
    }
    this.mountedForm = null
  }

  async signOut() {
    this.logoutTarget.disabled = true
    try {
      await this.clerk.signOut({ redirectUrl: "/" })
    } catch {
      this.logoutTarget.disabled = false
      this.showError("Could not log out. Please try again.")
    }
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.hidden = false
  }
}
