import AppKit
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var audioManager: AudioManager?
    var eqManager: EQManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application started")

        audioManager = AudioManager()
        eqManager = audioManager?.getEQManager()

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "mac-eq"
        window.makeKeyAndOrderFront(nil)

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        window.contentView = content

        let label = NSTextField(labelWithString: "mac-eq: 10-Band Equalizer")
        label.frame = NSRect(x: 20, y: 460, width: 560, height: 30)
        label.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        content.addSubview(label)

        let status = NSTextField(labelWithString: "Audio engine running")
        status.frame = NSRect(x: 20, y: 430, width: 560, height: 20)
        content.addSubview(status)

        setupEQControls(in: content)
    }

    private func setupEQControls(in content: NSView) {
        guard let eqManager = eqManager else { return }

        let frequencies = eqManager.getFrequencies()
        let sliderWidth: CGFloat = 40
        let sliderHeight: CGFloat = 200
        let startX: CGFloat = 30
        let startY: CGFloat = 30
        let spacing: CGFloat = 50

        for (index, freq) in frequencies.enumerated() {
            let x = startX + CGFloat(index) * spacing

            let label = NSTextField(labelWithString: formatFrequency(freq))
            label.frame = NSRect(x: x - 10, y: startY + sliderHeight + 10, width: 60, height: 20)
            label.alignment = .center
            label.font = NSFont.systemFont(ofSize: 10)
            content.addSubview(label)

            let slider = NSSlider(value: 0, minValue: -20, maxValue: 20, target: self, action: #selector(sliderChanged(_:)))
            slider.frame = NSRect(x: x, y: startY, width: sliderWidth, height: sliderHeight)
            slider.tag = index
            content.addSubview(slider)

            let valueLabel = NSTextField(labelWithString: "0.0 dB")
            valueLabel.frame = NSRect(x: x - 15, y: startY - 25, width: 70, height: 20)
            valueLabel.alignment = .center
            valueLabel.font = NSFont.systemFont(ofSize: 10)
            valueLabel.identifier = NSUserInterfaceItemIdentifier("value_\(index)")
            content.addSubview(valueLabel)
        }
    }

    @objc private func sliderChanged(_ sender: NSSlider) {
        let band = sender.tag
        let gain = Float(sender.floatValue)
        eqManager?.setGain(for: band, gain: gain)

        if let valueLabel = window.contentView?.viewWithIdentifier(NSUserInterfaceItemIdentifier("value_\(band)")) as? NSTextField {
            valueLabel.stringValue = String(format: "%.1f dB", gain)
        }
    }

    private func formatFrequency(_ freq: Float) -> String {
        if freq >= 1000 {
            return String(format: "%.0fK", freq / 1000)
        }
        return String(format: "%.0f", freq)
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("Application terminating")
        audioManager?.stop()
    }
}