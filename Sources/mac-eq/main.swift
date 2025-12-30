import Foundation
import AppKit
import CoreAudio

print("mac-eq: Audio Controller Application")
print("Starting...")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()