# Homebrew distribution

OpenCode Status Bar is distributed through **Ilya's personal tap**, not `homebrew/cask`.

```sh
brew install --cask yiaany/tap/opencode-status-bar
open -a "OpenCode Status Bar"
```

Then connect the bundled plugin as described in the [README](README.md#2-connect-opencode). The cask does not modify your OpenCode configuration.

## Update

```sh
brew update
brew upgrade --cask yiaany/tap/opencode-status-bar
```

The app is currently ad-hoc signed, not Apple-notarized. See the README for first-launch guidance. The cask does not disable Gatekeeper.

## Release checklist

1. Run plugin type checks and tests, then `./build.sh --dmg`.
2. Verify both architectures, the bundle signature, Info.plist, bundled plugin, and DMG integrity.
3. Create a versioned GitHub release in `yiaany/opencode-status-bar`, attaching `OpenCodeStatusBar.dmg`.
4. Calculate `shasum -a 256 build/OpenCodeStatusBar.dmg` and update the version/checksum in `packaging/opencode-status-bar.rb`.
5. Copy the verified cask to `Casks/opencode-status-bar.rb` in `yiaany/homebrew-tap` and push.
6. Test an install from the published tap. Never use `sha256 :no_check` for releases.
