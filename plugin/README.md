# OpenCode Status Bar plugin

Local event bridge and experimental GUI navigation for [OpenCode Status Bar](https://github.com/yiaany/opencode-status-bar).

The macOS app bundles this directory. Load it through the global OpenCode V2 `plugins` array using its absolute directory path. See the main repository's installation instructions. This package is not currently published to npm.

Session titles, directory paths, status labels, IDs, and timestamps are written locally under `~/.opencode/status-bar/sessions/`. Prompts, tool arguments, and transcripts are not saved.

For development: `npm ci`, `npm run check`, and `npm test`. The GUI entry is plain CommonJS, loaded by OpenCode Desktop. Its deep-link integration is experimental and supports the local Desktop server only.
