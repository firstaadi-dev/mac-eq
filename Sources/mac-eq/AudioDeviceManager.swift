import Foundation
import CoreAudio

struct AudioDevice {
    let id: AudioDeviceID
    let name: String
    let isOutput: Bool
}

class AudioDeviceManager {
    private var outputDevices: [AudioDevice] = []
    private var currentOutputDevice: AudioDeviceID?

    init() {
        refreshDevices()
    }

    func refreshDevices() {
        outputDevices = []

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var propertySize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize
        )

        guard status == noErr else {
            print("Error getting device data size: \(status)")
            return
        }

        let deviceCount = Int(propertySize / MemoryLayout<AudioDeviceID>.size)
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceIDs
        )

        for deviceId in deviceIDs {
            if let device = getDeviceInfo(deviceId: deviceId) {
                if device.isOutput {
                    outputDevices.append(device)
                }
            }
        }

        print("Found \(outputDevices.count) output devices")
    }

    private func getDeviceInfo(deviceId: AudioDeviceID) -> AudioDevice? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var propertySize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceId, &propertyAddress, 0, nil, &propertySize)

        guard status == noErr && propertySize > 0 else {
            return nil
        }

        var nameAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name: CFString = "" as CFString
        var nameSize = UInt32(MemoryLayout<CFString>.size)
        AudioObjectGetPropertyData(deviceId, &nameAddress, 0, nil, &nameSize, &name)

        return AudioDevice(
            id: deviceId,
            name: name as String,
            isOutput: true
        )
    }

    func getOutputDevices() -> [AudioDevice] {
        return outputDevices
    }

    func setCurrentOutputDevice(_ deviceId: AudioDeviceID) {
        var device = deviceId
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &device
        )

        if status == noErr {
            currentOutputDevice = deviceId
            print("Set output device to: \(deviceId)")
        } else {
            print("Error setting output device: \(status)")
        }
    }

    func getCurrentOutputDevice() -> AudioDeviceID? {
        return currentOutputDevice
    }
}