import AppKit
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application started")

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "mac-eq"
        window.makeKeyAndOrderFront(nil)

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        window.contentView = content

        let label = NSTextField(labelWithString: "mac-eq: Audio Controller")
        label.frame = NSRect(x: 20, y: 250, width: 360, height: 30)
        label.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        content.addSubview(label)

        let status = NSTextField(labelWithString: "Initializing audio engine...")
        status.frame = NSRect(x: 20, y: 200, width: 360, height: 20)
        content.addSubview(status)
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("Application terminating")
    }
}