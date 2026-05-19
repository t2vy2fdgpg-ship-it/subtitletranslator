import ReplayKit
import AVFoundation

// MARK: - Broadcast Sample Handler
/// Captures system audio during broadcast and forwards it to the main app via App Group.
final class SampleHandler: RPBroadcastSampleHandler {

    // Audio converter for PCM extraction
    private var audioConverter: AVAudioConverter?

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        print("[BroadcastExt] Broadcast started")
        // Notify main app
        AppGroupQueue.shared.enqueueSubtitleUpdate(
            "Broadcast Started", translated: "广播已启动",
            sourceLang: "en-US", targetLang: "zh-Hans", confidence: 1.0
        )
    }

    override func broadcastPaused() {
        print("[BroadcastExt] Broadcast paused")
    }

    override func broadcastResumed() {
        print("[BroadcastExt] Broadcast resumed")
    }

    override func broadcastFinished() {
        print("[BroadcastExt] Broadcast finished")
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard sampleBufferType == .audioApp || sampleBufferType == .audioMic else {
            return
        }

        // Extract audio data from CMSampleBuffer
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return
        }

        let audioDesc = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)!.pointee

        // Get PCM data
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

        var dataLength = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(
            blockBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &dataLength,
            dataPointerOut: &dataPointer
        )

        guard let pointer = dataPointer, dataLength > 0 else { return }

        let audioData = Data(bytes: pointer, count: dataLength)

        // Create chunk and enqueue for main app
        let chunk = AudioBufferChunk(
            id: UUID(),
            timestamp: Date().timeIntervalSince1970,
            sampleRate: audioDesc.mSampleRate,
            channelCount: Int(audioDesc.mChannelsPerFrame),
            data: audioData
        )

        AppGroupQueue.shared.enqueue([chunk])
    }
}
