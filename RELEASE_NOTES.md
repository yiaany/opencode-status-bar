# OpenCode Status Bar 0.1.0

Your OpenCode agents, at a glance—right in the macOS menu bar.

- Native Swift/AppKit app, universal for Apple Silicon and Intel, macOS 12+.
- Smooth time-based spinner and stable Thinking… brightness animation.
- Readable elapsed timer, yellow approval status, blue unread completion status.
- Direct session list and one-click navigation to the exact OpenCode Desktop session.
- Bundled OpenCode V2 server and GUI plugin; no separate npm package required.
- Local status files only; no analytics, prompts, transcripts, or credentials stored.

## Install

```sh
brew install --cask yiaany/tap/opencode-status-bar
open -a "OpenCode Status Bar"
```

Or download `OpenCodeStatusBar.dmg` below and drag the app into Applications.

**Setup is required:** add `/Applications/OpenCode Status Bar.app/Contents/Resources/plugin` to the global OpenCode `plugins` array. See the README for the complete example.

## Verification

Plugin type checking and five automated status/navigation tests pass. An isolated macOS UI smoke test confirms Thinking → Awaiting approval → Completed. Universal architectures, bundle signature, plist, and DMG integrity were checked locally. This is not a claim of testing every OpenCode version or a fresh Intel Mac.

## Known limitations

- Ad-hoc signed, **not Apple-notarized**. Gatekeeper may require Privacy & Security → Open Anyway.
- Experimental OpenCode V2 GUI integration; tested with Desktop 2.2.0. Exact navigation targets the local Desktop server, not terminal windows or remote servers.
- First-load tracking begins with subsequent events. Abnormally terminated sessions can leave state for up to 24 hours.
- The upstream OpenCode SDK dependency tree currently has 24 moderate npm audit findings; no high/critical findings. See SECURITY.md.
- Distributed through Ilya's personal tap, not the official Homebrew cask repository.

Maintained by Ilya / @yiaany. MIT licensed; third-party notices retained.
