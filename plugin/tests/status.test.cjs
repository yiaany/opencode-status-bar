const { test } = require("node:test")
const assert = require("node:assert/strict")
const { readFileSync } = require("node:fs")
const { stripTypeScriptTypes } = require("node:module")
const vm = require("node:vm")
const path = require("node:path")

async function run(events, { directory = "/project", pending = () => [] } = {}) {
  const files = new Map()
  const snapshots = []
  let finished
  const done = new Promise((resolve) => { finished = resolve })
  const fakeFS = {
    mkdir: async () => {},
    readdir: async () => [],
    readFile: async (file) => { if (!files.has(file)) throw new Error("ENOENT"); return files.get(file) },
    writeFile: async (file, data) => { files.set(file, data) },
    rename: async (from, to) => { files.set(to, files.get(from)); files.delete(from) },
    rm: async (file) => { files.delete(file) },
  }
  const source = stripTypeScriptTypes(readFileSync(path.join(__dirname, "../src/index.ts"), "utf8"))
    .replace(/^import .* from .*$/gm, "")
    .replace("export default", "globalThis.plugin =")
  const sandbox = {
    ...fakeFS, join: path.join, homedir: () => "/test-home", randomUUID: () => "temporary",
    Plugin: { define: (value) => value }, AbortController, console,
  }
  vm.runInNewContext(source, sandbox)
  const cleanup = await sandbox.plugin.setup({
    location: { directory: "/project" },
    session: { get: async () => ({ title: "Test session", location: { directory } }) },
    permission: { list: async () => pending(snapshots.length) },
    event: { subscribe: async function* () {
      try {
        for (const event of events) {
          yield { created: Date.now(), data: { sessionID: "ses_test", ...event.data }, ...event }
          snapshots.push([...files.values()].map((value) => JSON.parse(value)))
        }
      } finally { finished() }
    } },
  })
  await done
  await cleanup()
  assert.ok([...files.keys()].every((file) => file.endsWith(".json")), "no temporary files left")
  return snapshots
}

test("working → permission → completion → viewed", async () => {
  const states = await run([
    { type: "session.execution.started" },
    { type: "permission.asked" },
    { type: "session.step.started" },
    { type: "permission.replied" },
    { type: "session.execution.succeeded" },
    { type: "session.idle" },
    { type: "session.viewed" },
  ], { pending: (index) => index === 2 ? [{}] : [] })
  assert.deepEqual(states.map((items) => items[0]?.state), ["working", "permission", "permission", "working", "unread", "unread", undefined])
  assert.equal(states[4][0].label, "Completed")
})

test("viewing a busy session does not hide it", async () => {
  const states = await run([{ type: "session.execution.started" }, { type: "session.viewed" }])
  assert.equal(states[1][0].state, "working")
  assert.equal(states[0][0].startedAt, states[1][0].startedAt)
})

test("events belonging to another project do not create state", async () => {
  const states = await run([{ type: "session.execution.started" }], { directory: "/other-project" })
  assert.deepEqual(states, [[]])
})

test("failed, interrupted, and deleted sessions", async () => {
  const states = await run([
    { type: "session.execution.failed" },
    { type: "session.execution.interrupted" },
    { type: "session.deleted" },
  ])
  assert.equal(states[0][0].label, "Failed")
  assert.equal(states[1][0].label, "Interrupted")
  assert.deepEqual(states[2], [])
})

test("GUI links focus exact existing tabs or open a local session", () => {
  let listener
  let removed = false
  const calls = []
  const sandbox = {
    require: () => ({ Plugin: { define: (value) => value } }), exports: {}, URL, console,
    window: {
      addEventListener: (name, handler) => { assert.equal(name, "opencode:deep-link"); listener = handler },
      removeEventListener: () => { removed = true },
    },
  }
  vm.runInNewContext(readFileSync(path.join(__dirname, "../gui-experimental.cjs"), "utf8"), sandbox)
  const cleanup = sandbox.exports.default.setup({ tabs: {
    list: () => [{ key: "existing", session: { id: "ses_known" } }],
    focus: (key) => calls.push(key),
    open: (session, options) => calls.push(JSON.parse(JSON.stringify({ session, options }))),
  } })
  listener({ detail: { urls: [
    "opencode://status-bar/open?session=ses_known",
    "opencode://status-bar/open?session=ses_new",
    "https://example.org/open?session=ses_evil",
    "opencode://status-bar/open?session=../../bad",
  ] } })
  assert.deepEqual(calls, ["existing", { session: { server: "sidecar", id: "ses_new" }, options: { focus: true } }])
  cleanup()
  assert.equal(removed, true)
})
