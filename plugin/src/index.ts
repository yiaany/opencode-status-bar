import { Plugin } from "@opencode/plugin"
import { mkdir, writeFile, rm, readdir, readFile, rename } from "node:fs/promises"
import { join } from "node:path"
import { homedir } from "node:os"
import { randomUUID } from "node:crypto"

type State = { id: string; state: string; label: string; directory: string; title?: string; startedAt: number; updatedAt: number; source: string }
const root = join(homedir(), ".opencode", "status-bar", "sessions")

export default Plugin.define({
  id: "opencode-status-bar",
  async setup(ctx) {
    await mkdir(root, { recursive: true })
    // This directory is shared by all OpenCode locations. Never clear it here:
    // every project loads its own plugin instance and clearing would erase other
    // projects' live sessions. Only remove genuinely stale records.
    for (const file of await readdir(root).catch(() => [])) {
      if (!file.endsWith(".json")) continue
      try {
        const value = JSON.parse(await readFile(join(root, file), "utf8")) as State
        if (Date.now() / 1000 - value.updatedAt > 24 * 60 * 60) await rm(join(root, file), { force: true })
      } catch { await rm(join(root, file), { force: true }) }
    }
    const controller = new AbortController()
    let starts = new Map<string, number>()
    const save = async (id: string, state: string, label: string) => {
      // Events are server-wide, not scoped to this plugin instance's directory.
      const session = await ctx.session.get({ sessionID: id as any })
      if (session.location.directory !== ctx.location.directory) return
      // Permission requests remain authoritative until replied to, including
      // requests already pending when this plugin loaded.
      if (state === "working" || state === "tool") {
        const pending = await ctx.permission.list({ sessionID: id as any })
        if (pending.length > 0) { state = "permission"; label = "Awaiting approval" }
      }
      const now = Date.now() / 1000
      if (!starts.has(id) && (state === "working" || state === "tool" || state === "permission")) starts.set(id, now)
      const value: State = { id, state, label, directory: session.location.directory, title: session.title, startedAt: starts.get(id) ?? 0, updatedAt: now, source: "opencode" }
      const path = statePath(id)
      const temporary = `${path}.${randomUUID()}.tmp`
      await writeFile(temporary, JSON.stringify(value), "utf8")
      await rename(temporary, path)
    }
    const statePath = (id: string) => join(root, encodeURIComponent(id) + ".json")
    const readState = async (id: string): Promise<State | undefined> => {
      try { return JSON.parse(await readFile(statePath(id), "utf8")) as State } catch { return undefined }
    }
    const idOf = (event: any) => event.data?.sessionID ?? event.properties?.sessionID ?? event.properties?.info?.id ?? event.properties?.session?.id
    const labelOf = (event: any, fallback: string) => {
      const tool = event.data?.tool ?? event.data?.part?.tool
      return tool ? `${fallback}: ${String(tool)}` : fallback
    }
    const updates = (async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        const id = idOf(event)
        if (!id) continue
        try {
          switch (event.type) {
            case "session.status": {
              const status = event.data?.status?.type
              if (status === "busy") await save(id, "working", "Thinking…")
              else if (status === "retry") await save(id, "working", "Retrying…")
              else if ((await readState(id))?.state !== "unread") await rm(statePath(id), { force: true })
              break
            }
            case "session.idle": if ((await readState(id))?.state !== "unread") await rm(statePath(id), { force: true }); break
            case "session.execution.started": starts.set(id, event.created / 1000); await save(id, "working", "Thinking…"); break
            case "session.step.started": await save(id, "working", "Thinking…"); break
            case "session.tool.called": await save(id, "tool", labelOf(event, "Using tool")); break
            case "session.tool.success": await save(id, "working", "Thinking…"); break
            case "session.tool.failed": await save(id, "working", "Recovering…"); break
            case "permission.asked": await save(id, "permission", "Awaiting approval"); break
            case "permission.replied": await save(id, "working", "Continuing…"); break
            case "session.execution.succeeded": starts.delete(id); await save(id, "unread", "Completed"); break
            case "session.execution.failed": starts.delete(id); await save(id, "unread", "Failed"); break
            case "session.execution.interrupted": starts.delete(id); await save(id, "unread", "Interrupted"); break
            case "session.viewed": if ((await readState(id))?.state === "unread") await rm(statePath(id), { force: true }); break
            case "session.deleted": starts.delete(id); await rm(join(root, encodeURIComponent(id) + ".json"), { force: true }); break
          }
        } catch (error) { console.warn(`opencode-status-bar state update failed: ${String(error)}`) }
      }
    })().catch((error) => {
      if (!controller.signal.aborted) console.warn(`opencode-status-bar event stream failed: ${String(error)}`)
    })
    return async () => { controller.abort(); await updates }
  },
})
