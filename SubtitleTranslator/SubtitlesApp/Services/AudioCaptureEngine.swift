import AVFoundation
import Combine
import CoreMedia

// MARK: - Audio Capture Engine
/// Captures audio from system playback via ReplayKit Broadcast Extension,
/// with a fallback to AVAudioEngine microphone capture for testing.
final class AudioCaptureEngine: ObservableObject {
    static let shared = AudioCaptureEngine()

    @Published var isCapturing = false
    @Published var audioLevel: Float = 0.0
    @Published var captureMode: CaptureMode = .none

    enum CaptureMode: String {
        case none = "未启动"
        case microphone = "麦克风收音"
        case broadcast = "系统内录"
    }

    // Audio engine for microphone fallback
    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let ringBuffer = AudioRingBuffer(maxChunks: 30)
    private var cancellables = Set<AnyCancellable>()

    // Callback for audio chunks
    var onAudioChunk: ((AVAudioPCMBuffer) -> Void)?

    private init() {
        self.inputNode = audioEngine.inputNode
    }

    /// Start capturing from microphone (fallback / development mode)
    func startMicrophoneCapture() throws {
        guard !audioEngine.isRunning else { return }

        let inputFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(
            onBus: 0,
            bufferSize: 4096,
            format: inputFormat
        ) { [weak self] pcmBuffer, _ in
            self?.processAudioBuffer(pcmBuffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        DispatchQueue.main.async {
            self.isCapturing = true
            self.captureMode = .microphone
        }
    }

    /// Stop microphone capture
    func stopMicrophoneCapture() {
        guard audioEngine.isRunning else { return }
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        DispatchQueue.main.async {
            self.isCapturing = false
            self.captureMode = .none
        }
    }

    /// Process audio from Broadcast Extension (called via App Group polling)
    func processBroadcastChunks() {
        let chunks = AppGroupQueue.shared.dequeueAll()
        for chunk in chunks {
            if let pcmBuffer = chunk.toPCMBuffer() {
                processAudioBuffer(pcmBuffer)
            }
        }
        if !chunks.isEmpty && captureMode != .broadcast {
            DispatchQueue.main.async {
                self.isCapturing = true
                self.captureMode = .broadcast
            }
        }
    }

    private func processAudioBuffer(_ pcmBuffer: AVAudioPCMBuffer) {
        // Calculate audio level
        let level = computeAudioLevel(pcmBuffer)
        DispatchQueue.main.async {
            self.audioLevel = level
        }
        // Forward to speech recognizer
        onAudioChunk?(pcmBuffer)
    }

    private func computeAudioLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))

        var sum: Float = 0
        for sample in samples {
            sum += abs(sample)
        }
        let avg = sum / Float(frameLength)
        return min(1.0, max(0.0, avg * 5.0))
    }

    /// Setup broadcast mode - called when user taps start
    func setupBroadcastMode() {
        DispatchQueue.main.async {
            self.isCapturing = true
            self.captureMode = .broadcast
        }
        // Start polling for chunks from broadcast extension
        startPolling()
    }

    private func startPolling() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.captureMode == .broadcast else { return }
            self.processBroadcastChunks()
        }
    }

    /// Process audio CMSampleBuffer directly (from Broadcast Extension handler)
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
        let audioDesc = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)!.pointee

        guard let audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: audioDesc.mSampleRate,
            channels: audioDesc.mChannelsPerFrame,
            interleaved: true
        ) else { return }

        let frameCount = CMSampleBufferGetNumSamples(sampleBuffer)
        guard let pcmBuffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat,
            frameCapacity: AVAudioFrameCount(frameCount)
        ) else { return }

        pcmBuffer.frameLength = AVAudioFrameCount(frameCount)

        let status = CMSampleBufferCopyPCMDataIntoAudioBufferList(
            sampleBuffer,
            at: 0,
            frameCount: Int32(frameCount),
            into: pcmBuffer.mutableAudioBufferList!
        )

        if status == noErr {
            processAudioBuffer(pcmBuffer)
        }
    }
}
