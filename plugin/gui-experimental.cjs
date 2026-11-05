// Plain CommonJS GUI entry: no JSX or bundling is required.
const { Plugin } = require("@opencode/plugin/gui")

exports.default = Plugin.define({
  setup(ctx) {
    function openLink(raw) {
      try {
        const url = new URL(raw)
        if (url.protocol !== "opencode:" || url.hostname !== "status-bar" || url.pathname !== "/open") return
        const id = url.searchParams.get("session")
        if (!id || !/^ses_[a-zA-Z0-9]+$/.test(id)) return
        const tab = ctx.tabs.list().find((item) => item.session?.id === id)
        if (tab) ctx.tabs.focus(tab.key)
        else ctx.tabs.open({ server: "sidecar", id }, { focus: true })
      } catch (error) {
        console.warn("opencode-status-bar navigation failed", error)
      }
    }
    // OpenCode Desktop forwards OS deep links through this renderer event.
    function onLink(event) {
      for (const url of event.detail?.urls ?? []) openLink(url)
    }
    window.addEventListener("opencode:deep-link", onLink)
    for (const url of window.__OPENCODE__?.deepLinks ?? []) openLink(url)
    return () => window.removeEventListener("opencode:deep-link", onLink)
  },
})
