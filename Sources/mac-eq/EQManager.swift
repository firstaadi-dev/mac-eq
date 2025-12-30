import Foundation
import CoreAudio
import AudioToolbox

class EQManager {
    private var eqUnit: AudioUnit?
    private let frequencies: [Float] = [
        32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000
    ]
    private var gains: [Float] = Array(repeating: 0.0, count: 10)

    init() {
        setupEQ()
    }

    private func setupEQ() {
        var desc = AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: kAudioUnitSubType_NBandEQ,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        guard let component = AudioComponentFindNext(nil, &desc) else {
            print("Error: Could not find N-Band EQ component")
            return
        }

        let status = AudioComponentInstanceNew(component, &eqUnit)
        if status != noErr {
            print("Error: Could not create EQ instance: \(status)")
            return
        }

        AudioUnitInitialize(eqUnit!)
        setupBands()
    }

    private func setupBands() {
        guard let eqUnit = eqUnit else { return }

        for (index, frequency) in frequencies.enumerated() {
            var band = UInt32(index)

            let filterType: AUParameterID = 0
            let freq: Float = frequency
            let bw: Float = 1.0
            let gain: Float = 0.0

            AudioUnitSetParameter(eqUnit,
                AudioUnitPropertyID(kAUNBandEQParam_FilterType + UInt32(index)),
                kAudioUnitScope_Global,
                0,
                filterType,
                0)

            AudioUnitSetParameter(eqUnit,
                AudioUnitPropertyID(kAUNBandEQParam_Frequency + UInt32(index)),
                kAudioUnitScope_Global,
                0,
                freq,
                0)

            AudioUnitSetParameter(eqUnit,
                AudioUnitPropertyID(kAUNBandEQParam_Bandwidth + UInt32(index)),
                kAudioUnitScope_Global,
                0,
                bw,
                0)

            AudioUnitSetParameter(eqUnit,
                AudioUnitPropertyID(kAUNBandEQParam_Gain + UInt32(index)),
                kAudioUnitScope_Global,
                0,
                gain,
                0)
        }
    }

    func setGain(for band: Int, gain: Float) {
        guard band >= 0 && band < 10, let eqUnit = eqUnit else { return }
        gains[band] = gain

        let clampedGain = max(-20, min(20, gain))
        AudioUnitSetParameter(eqUnit,
            AudioUnitPropertyID(kAUNBandEQParam_Gain + UInt32(band)),
            kAudioUnitScope_Global,
            0,
            clampedGain,
            0)
    }

    func getGain(for band: Int) -> Float {
        guard band >= 0 && band < 10 else { return 0 }
        return gains[band]
    }

    func getFrequencies() -> [Float] {
        return frequencies
    }

    func getEQUnit() -> AudioUnit? {
        return eqUnit
    }

    func reset() {
        for i in 0..<10 {
            setGain(for: i, gain: 0)
        }
    }
}