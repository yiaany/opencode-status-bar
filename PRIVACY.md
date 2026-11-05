# Privacy

OpenCode Status Bar runs locally. The plugin writes session IDs, session titles, project directory paths, status/tool labels, and timestamps to `~/.opencode/status-bar/sessions/`. Titles and paths can contain private information. It does not store prompts, tool arguments, file contents, API keys, or transcripts. The macOS app reads those local state files and does not make network requests. Clicking a session sends its ID to OpenCode Desktop through a local `opencode://` link.

Delete that directory to remove all local status data. Uninstalling the plugin does not modify OpenCode configuration automatically.
