import Foundation
import CoreAudio
import AudioToolbox

class AudioManager {
    private var graph: AUGraph?
    private var eqUnit: AudioUnit?
    private var outputUnit: AudioUnit?
    private var eqManager: EQManager?

    init() {
        setupAudioGraph()
    }

    private func setupAudioGraph() {
        NewAUGraph(&graph)

        var eqDesc = AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: kAudioUnitSubType_NBandEQ,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        var outputDesc = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_DefaultOutput,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        var eqNode: AUNode = 0
        var outputNode: AUNode = 0

        AUGraphAddNode(graph!, &eqDesc, &eqNode)
        AUGraphAddNode(graph!, &outputDesc, &outputNode)

        AUGraphOpen(graph!)

        AUGraphNodeInfo(graph!, eqNode, nil, &eqUnit)
        AUGraphNodeInfo(graph!, outputNode, nil, &outputUnit)

        AUGraphConnectNodeInput(graph!, eqNode, 0, outputNode, 0)

        eqManager = EQManager()
        if let eqUnitFromManager = eqManager?.getEQUnit() {
            eqUnit = eqUnitFromManager
        }

        AUGraphInitialize(graph!)
        AUGraphStart(graph!)

        print("Audio graph started successfully")
    }

    func getEQManager() -> EQManager? {
        return eqManager
    }

    func stop() {
        guard let graph = graph else { return }
        AUGraphStop(graph)
        AUGraphUninitialize(graph)
        AUGraphClose(graph)
        DisposeAUGraph(graph)
        self.graph = nil
    }
}