import Foundation
import AVFoundation

// MARK: - Audio Buffer Chunk for Inter-Process Communication
struct AudioBufferChunk: Codable {
    let id: UUID
    let timestamp: TimeInterval
    let sampleRate: Double
    let channelCount: Int
    let data: Data  // Raw PCM Int16 samples

    init(sampleBuffer: CMSampleBuffer) throws {
        self.id = UUID()
        self.timestamp = Date().timeIntervalSince1970

        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            throw AudioBufferError.invalidFormat
        }
        let audioDesc = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)!.pointee
        self.sampleRate = audioDesc.mSampleRate
        self.channelCount = Int(audioDesc.mChannelsPerFrame)

        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            throw AudioBufferError.noData
        }
        var dataLength = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &dataLength, dataPointerOut: &dataPointer)

        if let pointer = dataPointer {
            self.data = Data(bytes: pointer, count: dataLength)
        } else {
            self.data = Data()
        }
    }

    func toPCMBuffer() -> AVAudioPCMBuffer? {
        guard let audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: AVAudioChannelCount(channelCount),
            interleaved: true
        ) else { return nil }

        let frameCount = data.count / (MemoryLayout<Int16>.size * channelCount)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return nil
        }
        pcmBuffer.frameLength = AVAudioFrameCount(frameCount)

        data.withUnsafeBytes { rawPtr in
            if let src = rawPtr.bindMemory(to: Int16.self).baseAddress,
               let dst = pcmBuffer.int16ChannelData?.pointee {
                dst.assign(from: src, count: frameCount * channelCount)
            }
        }
        return pcmBuffer
    }
}

enum AudioBufferError: Error {
    case invalidFormat
    case noData
}

// MARK: - Ring Buffer for Audio Streaming
final class AudioRingBuffer {
    private var buffer: [AudioBufferChunk] = []
    private let lock = NSLock()
    private let maxChunks: Int

    init(maxChunks: Int = 20) {
        self.maxChunks = maxChunks
    }

    func push(_ chunk: AudioBufferChunk) {
        lock.lock()
        defer { lock.unlock() }
        buffer.append(chunk)
        if buffer.count > maxChunks {
            buffer.removeFirst(buffer.count - maxChunks)
        }
    }

    func pop() -> AudioBufferChunk? {
        lock.lock()
        defer { lock.unlock() }
        guard !buffer.isEmpty else { return nil }
        return buffer.removeFirst()
    }

    func popAll() -> [AudioBufferChunk] {
        lock.lock()
        defer { lock.unlock() }
        let all = buffer
        buffer.removeAll()
        return all
    }

    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return buffer.isEmpty
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        buffer.removeAll()
    }
}

// MARK: - App Group Queue for Broadcast → Main App Communication
final class AppGroupQueue {
    static let shared = AppGroupQueue()
    private let defaults = UserDefaults(suiteName: AppGroupConstants.groupIdentifier)
    private let maxQueueSize = 50

    private init() {}

    func enqueue(_ chunks: [AudioBufferChunk]) {
        guard let defaults = defaults else { return }
        var current: [[String: Any]] = []
        if let existing = defaults.array(forKey: AppGroupConstants.audioBufferKey) as? [[String: Any]] {
            current = existing
        }
        for chunk in chunks {
            var dict: [String: Any] = [
                "id": chunk.id.uuidString,
                "timestamp": chunk.timestamp,
                "sampleRate": chunk.sampleRate,
                "channelCount": chunk.channelCount,
                "data": chunk.data.base64EncodedString()
            ]
            current.append(dict)
        }
        while current.count > maxQueueSize {
            current.removeFirst()
        }
        defaults.set(current, forKey: AppGroupConstants.audioBufferKey)
    }

    func dequeueAll() -> [AudioBufferChunk] {
        guard let defaults = defaults,
              let raw = defaults.array(forKey: AppGroupConstants.audioBufferKey) as? [[String: Any]] else {
            return []
        }
        defaults.removeObject(forKey: AppGroupConstants.audioBufferKey)
        return raw.compactMap { dict in
            guard let idStr = dict["id"] as? String,
                  let id = UUID(uuidString: idStr),
                  let timestamp = dict["timestamp"] as? TimeInterval,
                  let sampleRate = dict["sampleRate"] as? Double,
                  let channelCount = dict["channelCount"] as? Int,
                  let b64 = dict["data"] as? String,
                  let data = Data(base64Encoded: b64) else { return nil }
            return AudioBufferChunk(id: id, timestamp: timestamp, sampleRate: sampleRate, channelCount: channelCount, data: data)
        }
    }

    func enqueueSubtitleUpdate(_ text: String, translated: String, sourceLang: String, targetLang: String, confidence: Float) {
        guard let defaults = defaults else { return }
        let dict: [String: Any] = [
            "originalText": text,
            "translatedText": translated,
            "sourceLanguage": sourceLang,
            "targetLanguage": targetLang,
            "confidence": confidence,
            "timestamp": Date().timeIntervalSince1970
        ]
        defaults.set(dict, forKey: AppGroupConstants.subtitleUpdateKey)
    }
}

// Extend initializer for quick construction
extension AudioBufferChunk {
    init(id: UUID, timestamp: TimeInterval, sampleRate: Double, channelCount: Int, data: Data) {
        self.id = id
        self.timestamp = timestamp
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.data = data
    }
}
