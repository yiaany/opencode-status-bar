# Troubleshooting

## No active sessions

- Launch **OpenCode Status Bar**; it does not currently install a login item automatically.
- Add the bundled plugin's absolute directory path to `plugins` in your global OpenCode V2 configuration. See [setup](README.md#2-connect-opencode).
- Start a task after loading the plugin. Already-running tasks may not appear until their next event.
- Check whether JSON files appear under `~/.opencode/status-bar/sessions/` during a run. No files usually means the server plugin is not loaded.
- Use `/reload` in OpenCode if automatic configuration reload has not taken effect.

## Clicking only opens Desktop

Exact-session navigation requires the GUI plugin, loaded from the global configuration. It uses an experimental Desktop deep-link event and `ctx.tabs`; future OpenCode updates may require a plugin update. Local Desktop sessions are supported; remote/custom servers and terminal-window focus are not.

## macOS blocks the app

This release is not Apple-notarized. Verify it came from `yiaany/opencode-status-bar`, attempt to open it, and use **System Settings → Privacy & Security → Open Anyway** if offered. Do not globally disable Gatekeeper.

## A status is stuck

An OpenCode process terminated without final events can leave a record for up to 24 hours. Quit the indicator and remove only the affected session's JSON file from its status directory. Do not delete OpenCode databases or configuration. Start a new task and reopen the indicator.

## Reporting a bug

Include macOS, CPU architecture, OpenCode version, app version, steps to reproduce, and whether status files update. Redact session titles, project paths, credentials, and private content before sharing logs or screenshots.
