import Foundation
import Cocoa

class AppAudioSession: NSObject {
    let bundleId: String
    let appName: String
    var volume: Float
    var eqEnabled: Bool

    init(bundleId: String, appName: String, volume: Float, eqEnabled: Bool) {
        self.bundleId = bundleId
        self.appName = appName
        self.volume = volume
        self.eqEnabled = eqEnabled
    }
}

class AppMonitor {
    private var runningApps: [String: NSRunningApplication] = [:]
    private var audioSessions: [String: AppAudioSession] = [:]
    var onAppsChanged: (([AppAudioSession]) -> Void)?

    init() {
        startMonitoring()
    }

    private func startMonitoring() {
        updateRunningApps()

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateRunningApps()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appLaunched(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appTerminated(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
    }

    @objc private func appLaunched(_ notification: Notification) {
        updateRunningApps()
    }

    @objc private func appTerminated(_ notification: Notification) {
        updateRunningApps()
    }

    private func updateRunningApps() {
        let currentApps = NSWorkspace.shared.runningApplications

        var newRunningApps: [String: NSRunningApplication] = [:]
        var newSessions: [String: AppAudioSession] = [:]

        for app in currentApps {
            if let bundleId = app.bundleIdentifier,
               app.activationPolicy == .regular {
                newRunningApps[bundleId] = app

                let existingSession = audioSessions[bundleId]
                let session = AppAudioSession(
                    bundleId: bundleId,
                    appName: app.localizedName ?? "Unknown",
                    volume: existingSession?.volume ?? 1.0,
                    eqEnabled: existingSession?.eqEnabled ?? false
                )
                newSessions[bundleId] = session
            }
        }

        if runningApps != newRunningApps {
            runningApps = newRunningApps
            audioSessions = newSessions
            onAppsChanged?(Array(newSessions.values).sorted { $0.appName < $1.appName })
        }
    }

    func setVolume(for bundleId: String, volume: Float) {
        var session = audioSessions[bundleId]
        session?.volume = max(0, min(1, volume))
        if let session = session {
            audioSessions[bundleId] = session
        }
    }

    func getVolume(for bundleId: String) -> Float {
        return audioSessions[bundleId]?.volume ?? 1.0
    }

    func setEQEnabled(for bundleId: String, enabled: Bool) {
        var session = audioSessions[bundleId]
        session?.eqEnabled = enabled
        if let session = session {
            audioSessions[bundleId] = session
        }
    }

    func getAudioSessions() -> [AppAudioSession] {
        return Array(audioSessions.values).sorted { $0.appName < $1.appName }
    }
}