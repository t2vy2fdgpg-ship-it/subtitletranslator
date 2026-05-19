import Speech
import AVFoundation
import Combine

// MARK: - Speech Recognizer
/// Performs on-device (offline) speech recognition for Chinese and English.
final class SpeechRecognizer: ObservableObject {
    static let shared = SpeechRecognizer()

    @Published var isRecognizing = false
    @Published var recognizedText: String = ""
    @Published var interimResult: String = ""
    @Published var isAvailable = false
    @Published var supportsOnDeviceRecognition = false

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var currentLocale: Locale = Locale(identifier: "zh-Hans")

    private init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: currentLocale)
        checkAvailability()
    }

    private func checkAvailability() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAvailable = status == .authorized
                self?.supportsOnDeviceRecognition = self?.speechRecognizer?.supportsOnDeviceRecognition ?? false
                print("[SpeechRec] Auth: \(status.rawValue), OnDevice: \(self?.supportsOnDeviceRecognition ?? false)")
            }
        }
    }

    /// Switch recognition language
    func setLanguage(_ language: SubtitleLanguage) {
        let locale = Locale(identifier: language.localeIdentifier)
        currentLocale = locale

        // Recreate recognizer with new locale if needed
        let newRecognizer = SFSpeechRecognizer(locale: locale)
        if newRecognizer != nil {
            // We can't reassign speechRecognizer directly (it's a let).
            // Instead, stop and restart with new locale.
            stopRecognition()
            DispatchQueue.main.async { [weak self] in
                self?.supportsOnDeviceRecognition = newRecognizer?.supportsOnDeviceRecognition ?? false
            }
        }
    }

    /// Start real-time recognition
    func startRecognition(offlineMode: Bool) throws {
        stopRecognition()

        let locale = currentLocale
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            throw SpeechError.recognizerUnavailable
        }
        guard recognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = offlineMode

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                print("[SpeechRec] Recognition error: \(error.localizedDescription)")
                return
            }

            if let result = result {
                let transcript = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = transcript
                    self.interimResult = transcript

                    // Post notification for translation engine
                    if result.isFinal {
                        NotificationCenter.default.post(
                            name: .finalTranscriptionReady,
                            object: nil,
                            userInfo: [
                                "text": transcript,
                                "confidence": self.confidence(of: result.bestTranscription)
                            ]
                        )
                    }
                }
            }
        }

        DispatchQueue.main.async { self.isRecognizing = true }
    }

    /// Feed audio buffer for recognition
    func appendAudioBuffer(_ pcmBuffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(pcmBuffer)
    }

    /// Stop recognition
    func stopRecognition() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        DispatchQueue.main.async {
            self.isRecognizing = false
            self.interimResult = ""
        }
    }

    /// Get best transcription confidence
    private func confidence(of transcription: SFTranscription) -> Float {
        guard !transcription.segments.isEmpty else { return 0 }
        let totalConfidence = transcription.segments.reduce(0.0) { $0 + Double($1.confidence) }
        return Float(totalConfidence) / Float(transcription.segments.count)
    }

    /// Reset
    func reset() {
        stopRecognition()
        recognizedText = ""
        interimResult = ""
    }
}

// MARK: - Speech Errors
enum SpeechError: LocalizedError {
    case recognizerUnavailable
    case requestCreationFailed

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable: return "语音识别器不可用，请检查权限或下载离线语言包"
        case .requestCreationFailed: return "无法创建语音识别请求"
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let finalTranscriptionReady = Notification.Name("FinalTranscriptionReady")
}
