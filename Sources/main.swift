import Cocoa

struct SessionState: Codable {
    var id: String
    var state: String
    var label: String
    var directory: String
    var startedAt: Double
    var updatedAt: Double
    var source: String
    var title: String?
}

final class StatusController: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var item: NSStatusItem!
    private var timer: Timer!
    private var sessions: [String: SessionState] = [:]
    private let stateDirectory = ProcessInfo.processInfo.environment["OPENCODE_STATUS_BAR_STATE_DIR"]
        ?? (NSHomeDirectory() as NSString).appendingPathComponent(".opencode/status-bar/sessions")
    private var animation: CGFloat = 0
    private let animationStart = ProcessInfo.processInfo.systemUptime
    private let rotationDuration = 2.4
    private var lastStateRead = Date.distantPast
    private var menuIsOpen = false
    private var sessionsEndSeparator: NSMenuItem!
    func applicationDidFinishLaunching(_ notification: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.toolTip = "OpenCode Status Bar"
        item.menu = makeMenu()
        timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in self?.refresh() }
        RunLoop.main.add(timer, forMode: .common)
        refresh()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "OpenCode Status Bar", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        let placeholder = NSMenuItem(title: "No active sessions", action: nil, keyEquivalent: "")
        placeholder.tag = 200
        menu.addItem(placeholder)
        sessionsEndSeparator = .separator()
        menu.addItem(sessionsEndSeparator)
        let open = NSMenuItem(title: "Open OpenCode", action: #selector(openOpenCode), keyEquivalent: "")
        open.target = self; menu.addItem(open)
        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quit.target = self; menu.addItem(quit)
        return menu
    }

    private func refresh() {
        // Continuous angle from monotonic time: speed is independent of frame rate.
        let elapsed = ProcessInfo.processInfo.systemUptime - animationStart
        animation = CGFloat(elapsed.truncatingRemainder(dividingBy: rotationDuration) / rotationDuration * 360)
        guard Date().timeIntervalSince(lastStateRead) >= 0.2 else { render(); return }
        lastStateRead = Date()
        let fm = FileManager.default
        try? fm.createDirectory(atPath: stateDirectory, withIntermediateDirectories: true)
        var next: [String: SessionState] = [:]
        for file in (try? fm.contentsOfDirectory(atPath: stateDirectory)) ?? [] where file.hasSuffix(".json") {
            let path = (stateDirectory as NSString).appendingPathComponent(file)
            guard let data = fm.contents(atPath: path), let state = try? JSONDecoder().decode(SessionState.self, from: data) else { continue }
            if Date().timeIntervalSince1970 - state.updatedAt < 24 * 60 * 60 { next[state.id] = state } else { try? fm.removeItem(atPath: path) }
        }
        sessions = next
        render()
        if !menuIsOpen { updateMenu() }
    }

    private func render() {
        if menuIsOpen, let menu = item.menu {
            for row in menu.items where row.tag == 200 {
                if let id = row.representedObject as? String, let session = sessions[id] {
                    row.image = sessionIcon(session.state)
                }
            }
        }
        let lead = sessions.values.max { rank($0.state) == rank($1.state) ? $0.updatedAt < $1.updatedAt : rank($0.state) < rank($1.state) }
        guard let button = item.button else { return }
        guard let lead else {
            button.attributedTitle = NSAttributedString(string: "")
            button.image = icon(color: .secondaryLabelColor, phase: 0); button.title = ""; return
        }
        if lead.state == "permission" {
            button.attributedTitle = NSAttributedString(string: "")
            button.image = icon(color: .systemYellow, phase: 0)
            button.attributedTitle = NSAttributedString(string: " Awaiting approval", attributes: [.foregroundColor: NSColor.labelColor])
            button.setAccessibilityLabel("Awaiting approval")
        } else if lead.state == "working" || lead.state == "tool" {
            button.image = icon(color: .labelColor, phase: animation, phaseCount: 4)
            let seconds = max(0, Int(Date().timeIntervalSince1970 - lead.startedAt))
            let elapsed = ProcessInfo.processInfo.systemUptime - animationStart
            let reduced = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            let label = lead.label == "Working…" ? "Thinking…" : lead.label
            let title = NSMutableAttributedString(string: " ")
            let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            for (index, character) in label.enumerated() {
                // Slow brightness-only wave: stable text, baseline, and width.
                let phase = (elapsed - Double(index) * 0.07) / 1.6 * 2 * Double.pi
                let alpha = reduced ? 1 : 0.75 + 0.25 * cos(phase)
                title.append(NSAttributedString(string: String(character), attributes: [
                    .font: font,
                    .foregroundColor: NSColor.labelColor.withAlphaComponent(alpha)
                ]))
            }
            if lead.startedAt > 0 {
                title.append(NSAttributedString(string: "  \(seconds / 60)m \(seconds % 60)s", attributes: [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
                    .foregroundColor: NSColor.labelColor
                ]))
            }
            button.attributedTitle = title
            button.setAccessibilityLabel("\(lead.label), \(seconds) seconds")
        } else if lead.state == "unread" {
            button.image = icon(color: .systemBlue, phase: 0)
            button.attributedTitle = NSAttributedString(string: " Completed", attributes: [
                .foregroundColor: NSColor.labelColor,
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            ])
            button.setAccessibilityLabel("Completed, unread session")
        } else {
            button.attributedTitle = NSAttributedString(string: "")
            button.image = icon(color: .secondaryLabelColor, phase: 0); button.title = ""
        }
    }

    private func updateMenu() {
        guard let menu = item.menu, let endSeparator = sessionsEndSeparator else { return }
        menu.items.filter { $0.tag == 200 }.forEach { menu.removeItem($0) }
        let insertIndex = menu.index(of: endSeparator)
        if sessions.isEmpty {
            let placeholder = NSMenuItem(title: "No active sessions", action: nil, keyEquivalent: "")
            placeholder.tag = 200
            menu.insertItem(placeholder, at: insertIndex)
            return
        }
        for s in sessions.values.sorted(by: { $0.updatedAt > $1.updatedAt }) {
            let project = s.title ?? (s.directory.isEmpty ? "OpenCode session" : (s.directory as NSString).lastPathComponent)
            let text = project + (s.label.isEmpty ? "" : " — \(s.label)")
            let row = NSMenuItem(title: text, action: #selector(openSession(_:)), keyEquivalent: "")
            row.tag = 200
            row.target = self
            row.representedObject = s.id
            row.image = sessionIcon(s.state)
            menu.insertItem(row, at: menu.index(of: endSeparator))
        }
    }

    private func sessionIcon(_ state: String) -> NSImage {
        let working = state == "working" || state == "tool"
        return icon(color: state == "permission" ? .systemYellow : (working ? .labelColor : .systemBlue), phase: animation, phaseCount: working ? 12 : 1)
    }

    func menuWillOpen(_ menu: NSMenu) {
        menuIsOpen = true
    }

    func menuDidClose(_ menu: NSMenu) { menuIsOpen = false }

    private func rank(_ state: String) -> Int { state == "permission" ? 3 : (state == "working" || state == "tool" ? 2 : 1) }

    private func icon(color: NSColor, phase: CGFloat, phaseCount: Int = 1) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            color.setFill()
            let center = NSPoint(x: rect.midX, y: rect.midY)
            if phaseCount == 1 {
                NSBezierPath(ovalIn: NSRect(x: 5, y: 5, width: 8, height: 8)).fill()
            } else {
                // LoaderCircle-style spinner: subtle ring and a rotating open arc.
                color.withAlphaComponent(0.18).setStroke()
                let ring = NSBezierPath(ovalIn: NSRect(x: 3, y: 3, width: 12, height: 12))
                ring.lineWidth = 1.8
                ring.stroke()
                color.setStroke()
                let arc = NSBezierPath()
                arc.lineWidth = 1.8
                arc.lineCapStyle = .round
                let angle = -phase
                arc.appendArc(withCenter: center, radius: 6, startAngle: angle, endAngle: angle + 250)
                arc.stroke()
            }
            return true
        }
        image.isTemplate = false
        return image
    }

    @objc private func openOpenCode() { NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/OpenCode.app")) }
    @objc private func openSession(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        // OpenCode Desktop registers opencode:// (oc:// is only an internal Electron scheme).
        if let url = URL(string: "opencode://status-bar/open?session=\(id)") { NSWorkspace.shared.open(url) }
        else { openOpenCode() }
    }
    @objc private func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = StatusController()
app.delegate = delegate
app.run()
