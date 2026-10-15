import AppKit

func dbg(_ msg: String) {
    guard isatty(STDERR_FILENO) != 0 else { return }
    fputs("[SpinBar] \(msg)\n", stderr)
}

// Manual entry point — required for swiftc single-file compilation (no @main)
dbg("Process started, pid=\(ProcessInfo.processInfo.processIdentifier)")

let app = NSApplication.shared
dbg("NSApplication.shared obtained")

// Set activation policy BEFORE run() — setting it inside applicationDidFinishLaunching
// can be too late for the status bar item to appear reliably.
app.setActivationPolicy(.accessory)
dbg("Activation policy set to .accessory")

let delegate = AppDelegate()
app.delegate = delegate
dbg("Delegate assigned, calling app.run()")
app.run()

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var caffeinateProcess: Process?
    private var isSpinning = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        dbg("applicationDidFinishLaunching fired")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        dbg("statusItem created: \(statusItem as Any)")

        guard let button = statusItem.button else {
            dbg("ERROR: statusItem.button is nil — status item will not appear")
            return
        }
        dbg("button obtained: \(button)")

        setIcon(spinning: false)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.action = #selector(handleClick)
        button.target = self
        dbg("Button configured with icon (off)")
    }

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else {
            dbg("handleClick: no current event")
            return
        }
        dbg("handleClick: event type=\(event.type.rawValue)")

        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.delegate = self
            menu.addItem(NSMenuItem(
                title: "Quit SpinBar",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            ))
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            return
        }

        isSpinning.toggle()
        dbg("Toggled isSpinning to \(isSpinning)")
        if isSpinning {
            startCaffeinate()
            setIcon(spinning: true)
        } else {
            stopCaffeinate()
            setIcon(spinning: false)
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }

    private func setIcon(spinning: Bool) {
        let name = spinning ? "bolt.fill" : "moon.zzz"
        if let img = NSImage(systemSymbolName: name, accessibilityDescription: spinning ? "Spinning" : "Spin Off") {
            img.isTemplate = true
            statusItem.button?.image = img
            statusItem.button?.title = ""
        } else {
            // Fallback if SF Symbols unavailable
            statusItem.button?.title = spinning ? "⚡" : "○"
        }
        dbg("Icon set to \(name)")
    }

    private func startCaffeinate() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = ["-dimsu"]
        do {
            try p.run()
            caffeinateProcess = p
            dbg("caffeinate started, pid=\(p.processIdentifier)")
        } catch {
            dbg("ERROR starting caffeinate: \(error)")
        }
    }

    private func stopCaffeinate() {
        if let p = caffeinateProcess {
            p.terminate()
            dbg("caffeinate terminated (was pid=\(p.processIdentifier))")
        }
        caffeinateProcess = nil
    }

    func applicationWillTerminate(_ notification: Notification) {
        dbg("applicationWillTerminate — cleaning up")
        stopCaffeinate()
    }
}
