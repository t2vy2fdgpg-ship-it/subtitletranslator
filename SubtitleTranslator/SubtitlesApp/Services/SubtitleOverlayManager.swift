import Foundation
import Combine
import SwiftUI

// MARK: - Subtitle Overlay Manager
/// Manages the floating subtitle window lifecycle, coordinates between
/// speech recognition and translation engines, and maintains subtitle history.
final class SubtitleOverlayManager: ObservableObject {
    static let shared = SubtitleOverlayManager()

    @Published var subtitleItems: [SubtitleItem] = []
    @Published var isOverlayVisible = false
    @Published var currentOriginal: String = ""
    @Published var currentTranslation: String = ""

    private let maxHistoryCount = 50
    private var cancellables = Set<AnyCancellable>()
    private let historyKey = "com.subtitletranslator.history"

    private init() {
        loadHistory()
        setupObservers()
    }

    private func setupObservers() {
        // Listen for final transcriptions
        NotificationCenter.default.publisher(for: .finalTranscriptionReady)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let text = notification.userInfo?["text"] as? String,
                      let confidence = notification.userInfo?["confidence"] as? Float else { return }
                self?.processTranscript(text, confidence: confidence)
            }
            .store(in: &cancellables)
    }

    /// Process a new transcript - translate and add to display queue
    func processTranscript(_ text: String, confidence: Float = 1.0) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let settings = AppSettings.shared
        let source = settings.sourceLanguage
        let target = settings.targetLanguage

        // Auto sentence splitting
        let processedText: String
        if settings.autoSplitSentence {
            processedText = splitSentence(trimmed)
        } else {
            processedText = trimmed
        }

        // Update current original
        DispatchQueue.main.async {
            self.currentOriginal = processedText
        }

        // Translate
        TranslationEngine.shared.translate(
            text: processedText,
            from: source,
            to: target
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let translated):
                    self?.currentTranslation = translated
                    let item = SubtitleItem(
                        originalText: processedText,
                        translatedText: translated,
                        sourceLanguage: source.localeIdentifier,
                        targetLanguage: target.localeIdentifier,
                        confidence: confidence
                    )
                    self?.addSubtitleItem(item)

                case .failure(let error):
                    print("[Overlay] Translation failed: \(error.localizedDescription)")
                    let item = SubtitleItem(
                        originalText: processedText,
                        translatedText: "[翻译失败]",
                        sourceLanguage: source.localeIdentifier,
                        targetLanguage: target.localeIdentifier,
                        confidence: confidence
                    )
                    self?.addSubtitleItem(item)
                }
            }
        }
    }

    private func addSubtitleItem(_ item: SubtitleItem) {
        subtitleItems.append(item)
        if subtitleItems.count > maxHistoryCount {
            subtitleItems.removeFirst()
        }
        saveHistory()

        // Update widget / Live Activity
        AppGroupQueue.shared.enqueueSubtitleUpdate(
            item.originalText,
            translated: item.translatedText,
            sourceLang: item.sourceLanguage,
            targetLang: item.targetLanguage,
            confidence: item.confidence
        )
    }

    /// Show the floating overlay
    func showOverlay() {
        DispatchQueue.main.async {
            self.isOverlayVisible = true
            OverlayWindowManager.shared.show()
        }
    }

    /// Hide the floating overlay
    func hideOverlay() {
        DispatchQueue.main.async {
            self.isOverlayVisible = false
            OverlayWindowManager.shared.hide()
        }
    }

    /// Clear all subtitle history
    func clearHistory() {
        subtitleItems.removeAll()
        currentOriginal = ""
        currentTranslation = ""
        UserDefaults.standard.removeObject(forKey: historyKey)
        AppSettings.shared.clearHistory()
    }

    // MARK: - Sentence Splitting
    private func splitSentence(_ text: String) -> String {
        // Split on common punctuation marks
        let punctuationSet = CharacterSet(charactersIn: ".!?。！？\n")
        if text.rangeOfCharacter(from: punctuationSet) != nil {
            return text
        }

        // For very long text without punctuation, split at ~40 chars
        if text.count > 40 {
            var result = ""
            var count = 0
            for char in text {
                result.append(char)
                count += 1
                if count % 35 == 0 && count < text.count {
                    result.append("\n")
                }
            }
            return result
        }

        return text
    }

    // MARK: - Persistence
    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(subtitleItems.suffix(20)) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let items = try? JSONDecoder().decode([SubtitleItem].self, from: data) else { return }
        subtitleItems = items
    }
}
