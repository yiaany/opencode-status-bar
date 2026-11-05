cask "opencode-status-bar" do
  version "0.1.0"
  sha256 "49ef2e7a9f8e959aca4550010b31086c16151569a4c06aeb979102ae1c282f15"

  url "https://github.com/yiaany/opencode-status-bar/releases/download/v#{version}/OpenCodeStatusBar.dmg"
  name "OpenCode Status Bar"
  desc "Native macOS menu-bar activity indicator for OpenCode"
  homepage "https://github.com/yiaany/opencode-status-bar"

  depends_on macos: :monterey

  app "OpenCode Status Bar.app"

  caveats <<~EOS
    Connect the bundled plugin in your global OpenCode V2 configuration:
      "plugins": ["/Applications/OpenCode Status Bar.app/Contents/Resources/plugin"]

    This release is ad-hoc signed, not Apple-notarized.
    See the project README for setup and first-launch guidance.
  EOS
end
