import AppKit
import Foundation

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var audioManager: AudioManager?
    var eqManager: EQManager?
    var valueLabels: [Int: NSTextField] = [:]
    var appMonitor: AppMonitor?
    var appListView: NSScrollView?
    var appListContainer: NSStackView?
    var deviceManager: AudioDeviceManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application started")

        audioManager = AudioManager()
        eqManager = audioManager?.getEQManager()
        appMonitor = AppMonitor()
        deviceManager = AudioDeviceManager()

        appMonitor?.onAppsChanged = { [weak self] sessions in
            self?.updateAppList(sessions: sessions)
        }

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "mac-eq"
        window.makeKeyAndOrderFront(nil)

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        window.contentView = content

        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: 760, height: 550))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        content.addSubview(scrollView)
        appListView = scrollView

        let stackView = NSStackView(frame: NSRect(x: 0, y: 0, width: 740, height: 0))
        stackView.orientation = .vertical
        stackView.spacing = 10
        stackView.alignment = .leading
        scrollView.documentView = stackView
        appListContainer = stackView

        let eqSection = createEQSection()
        stackView.addArrangedSubview(eqSection)

        let deviceSection = createDeviceSection()
        stackView.addArrangedSubview(deviceSection)

        let appsHeader = NSTextField(labelWithString: "Applications")
        appsHeader.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        appsHeader.frame = NSRect(x: 0, y: 0, width: 740, height: 30)
        stackView.addArrangedSubview(appsHeader)

        let status = NSTextField(labelWithString: "Audio engine running")
        status.frame = NSRect(x: 0, y: 0, width: 740, height: 20)
        status.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(status)
    }

    private func createEQSection() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 740, height: 280))

        let label = NSTextField(labelWithString: "Global 10-Band Equalizer")
        label.frame = NSRect(x: 0, y: 250, width: 740, height: 30)
        label.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        container.addSubview(label)

        setupEQControls(in: container)

        return container
    }

    private func setupEQControls(in container: NSView) {
        guard let eqManager = eqManager else { return }

        let frequencies = eqManager.getFrequencies()
        let sliderWidth: CGFloat = 65
        let sliderHeight: CGFloat = 150
        let startX: CGFloat = 20
        let startY: CGFloat = 50
        let spacing: CGFloat = 70

        for (index, freq) in frequencies.enumerated() {
            let x = startX + CGFloat(index) * spacing

            let label = NSTextField(labelWithString: formatFrequency(freq))
            label.frame = NSRect(x: x - 10, y: startY + sliderHeight + 5, width: 85, height: 20)
            label.alignment = .center
            label.font = NSFont.systemFont(ofSize: 10)
            container.addSubview(label)

            let slider = NSSlider(value: 0, minValue: -20, maxValue: 20, target: self, action: #selector(sliderChanged(_:)))
            slider.frame = NSRect(x: x, y: startY, width: sliderWidth, height: sliderHeight)
            slider.tag = index
            container.addSubview(slider)

            let valueLabel = NSTextField(labelWithString: "0.0 dB")
            valueLabel.frame = NSRect(x: x - 10, y: startY - 25, width: 85, height: 20)
            valueLabel.alignment = .center
            valueLabel.font = NSFont.systemFont(ofSize: 10)
            container.addSubview(valueLabel)
            valueLabels[index] = valueLabel
        }
    }

    private func updateAppList(sessions: [AppAudioSession]) {
        guard let container = appListContainer else { return }

        for view in container.arrangedSubviews.dropFirst(4) {
            container.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for session in sessions {
            let appRow = createAppRow(session: session)
            container.addArrangedSubview(appRow)
        }
    }

    private func createAppRow(session: AppAudioSession) -> NSView {
        let row = NSView(frame: NSRect(x: 0, y: 0, width: 740, height: 60))

        let icon = NSImageView(frame: NSRect(x: 0, y: 5, width: 50, height: 50))
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == session.bundleId }) {
            icon.image = app.icon
        }
        icon.imageScaling = .scaleProportionallyUpOrDown
        row.addSubview(icon)

        let nameLabel = NSTextField(labelWithString: session.appName)
        nameLabel.frame = NSRect(x: 60, y: 35, width: 200, height: 20)
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        row.addSubview(nameLabel)

        let volumeLabel = NSTextField(labelWithString: "Volume:")
        volumeLabel.frame = NSRect(x: 60, y: 10, width: 60, height: 16)
        volumeLabel.font = NSFont.systemFont(ofSize: 11)
        volumeLabel.textColor = .secondaryLabelColor
        row.addSubview(volumeLabel)

        let volumeSlider = NSSlider(value: Double(session.volume), minValue: 0, maxValue: 1, target: self, action: #selector(volumeChanged(_:)))
        volumeSlider.frame = NSRect(x: 120, y: 10, width: 200, height: 20)
        volumeSlider.identifier = NSUserInterfaceItemIdentifier("volume_\(session.bundleId)")
        row.addSubview(volumeSlider)

        let eqButton = NSButton(checkboxWithTitle: "Enable EQ", target: self, action: #selector(eqToggled(_:)))
        eqButton.frame = NSRect(x: 340, y: 25, width: 120, height: 20)
        eqButton.identifier = NSUserInterfaceItemIdentifier("eq_\(session.bundleId)")
        eqButton.state = session.eqEnabled ? .on : .off
        row.addSubview(eqButton)

        return row
    }

    @objc private func volumeChanged(_ sender: NSSlider) {
        guard let identifier = sender.identifier?.rawValue,
              identifier.hasPrefix("volume_"),
              let bundleId = identifier.split(separator: "_", maxSplits: 1).last.map(String.init) else { return }

        let volume = Float(sender.floatValue)
        appMonitor?.setVolume(for: bundleId, volume: volume)
    }

    @objc private func eqToggled(_ sender: NSButton) {
        guard let identifier = sender.identifier?.rawValue,
              identifier.hasPrefix("eq_"),
              let bundleId = identifier.split(separator: "_", maxSplits: 1).last.map(String.init) else { return }

        let enabled = sender.state == .on
        appMonitor?.setEQEnabled(for: bundleId, enabled: enabled)
    }

    @objc private func sliderChanged(_ sender: NSSlider) {
        let band = sender.tag
        let gain = Float(sender.floatValue)
        eqManager?.setGain(for: band, gain: gain)

        if let valueLabel = valueLabels[band] {
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

    private func createDeviceSection() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 740, height: 80))

        let label = NSTextField(labelWithString: "Output Device")
        label.frame = NSRect(x: 0, y: 50, width: 740, height: 30)
        label.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        container.addSubview(label)

        guard let deviceManager = deviceManager else {
            return container
        }

        let devices = deviceManager.getOutputDevices()

        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 10, width: 740, height: 30))
        for device in devices {
            popup.addItem(withTitle: device.name)
        }
        popup.target = self
        popup.action = #selector(deviceChanged(_:))
        container.addSubview(popup)

        return container
    }

    @objc private func deviceChanged(_ sender: NSPopUpButton) {
        guard let deviceManager = deviceManager else { return }

        let devices = deviceManager.getOutputDevices()
        let selectedIndex = sender.indexOfSelectedItem

        if selectedIndex >= 0 && selectedIndex < devices.count {
            deviceManager.setCurrentOutputDevice(devices[selectedIndex].id)
        }
    }