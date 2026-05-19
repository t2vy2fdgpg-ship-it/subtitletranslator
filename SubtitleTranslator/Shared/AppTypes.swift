import Foundation
import SwiftUI

// MARK: - Subtitle Item
struct SubtitleItem: Identifiable, Codable, Equatable {
    let id: UUID
    let originalText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let timestamp: Date
    let confidence: Float

    init(originalText: String, translatedText: String, sourceLanguage: String, targetLanguage: String, confidence: Float = 1.0) {
        self.id = UUID()
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.timestamp = Date()
        self.confidence = confidence
    }
}

// MARK: - Subtitle Language Setting
enum SubtitleLanguage: String, CaseIterable, Codable {
    case chinese = "zh-Hans"
    case english = "en-US"

    var displayName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        }
    }

    var shortName: String {
        switch self {
        case .chinese: return "中"
        case .english: return "EN"
        }
    }

    var localeIdentifier: String {
        self.rawValue
    }
}

// MARK: - Language Order
enum LanguageOrder: String, CaseIterable, Codable {
    case originalFirst = "original_first"
    case translationFirst = "translation_first"

    var displayName: String {
        switch self {
        case .originalFirst: return "原文在上"
        case .translationFirst: return "译文在上"
        }
    }
}

// MARK: - App Mode
enum AppMode: String, CaseIterable, Codable {
    case capture = "capture"
    case manual = "manual"

    var displayName: String {
        switch self {
        case .capture: return "自动收音"
        case .manual: return "手动输入"
        }
    }
}

// MARK: - Translation Engine Type
enum TranslationEngineType: String, CaseIterable, Codable {
    case appleNL = "apple_nl"

    var displayName: String {
        switch self {
        case .appleNL: return "Apple 本地引擎"
        }
    }
}

// MARK: - Float Window Position
struct WindowPosition: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat

    static let `default` = WindowPosition(x: 20, y: 100)
}

// MARK: - Subtitle Appearance
struct SubtitleAppearance: Codable, Equatable {
    var fontSize: CGFloat = 18.0
    var fontColor: CodableColor = CodableColor(.white)
    var backgroundColor: CodableColor = CodableColor(.black.opacity(0.6))
    var opacity: Double = 0.9
    var cornerRadius: CGFloat = 8.0
    var padding: CGFloat = 12.0
    var maxLines: Int = 2
}

// MARK: - Codable Color Wrapper
struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }

    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    var uiColor: UIColor {
        UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
}

// MARK: - App Settings
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var isEnabled: Bool {
        didSet { save() }
    }
    @Published var sourceLanguage: SubtitleLanguage {
        didSet { save() }
    }
    @Published var targetLanguage: SubtitleLanguage {
        didSet { save() }
    }
    @Published var languageOrder: LanguageOrder {
        didSet { save() }
    }
    @Published var offlineMode: Bool {
        didSet { save() }
    }
    @Published var autoSplitSentence: Bool {
        didSet { save() }
    }
    @Published var windowPosition: WindowPosition {
        didSet { save() }
    }
    @Published var appearance: SubtitleAppearance {
        didSet { save() }
    }

    private let defaultsKey = "com.subtitletranslator.settings"

    private init() {
        // Load or set defaults

        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(SettingsData.self, from: data) {
            self.isEnabled = decoded.isEnabled
            self.sourceLanguage = decoded.sourceLanguage
            self.targetLanguage = decoded.targetLanguage
            self.languageOrder = decoded.languageOrder
            self.offlineMode = decoded.offlineMode
            self.autoSplitSentence = decoded.autoSplitSentence
            self.windowPosition = decoded.windowPosition
            self.appearance = decoded.appearance
        } else {
            self.isEnabled = false
            self.sourceLanguage = .chinese
            self.targetLanguage = .english
            self.languageOrder = .originalFirst
            self.offlineMode = true
            self.autoSplitSentence = true
            self.windowPosition = .default
            self.appearance = SubtitleAppearance()
        }
    }

    private func save() {
        let data = SettingsData(
            isEnabled: isEnabled,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            languageOrder: languageOrder,
            offlineMode: offlineMode,
            autoSplitSentence: autoSplitSentence,
            windowPosition: windowPosition,
            appearance: appearance
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }

    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: "com.subtitletranslator.history")
    }
}

// MARK: - Codable Settings Data
private struct SettingsData: Codable {
    let isEnabled: Bool
    let sourceLanguage: SubtitleLanguage
    let targetLanguage: SubtitleLanguage
    let languageOrder: LanguageOrder
    let offlineMode: Bool
    let autoSplitSentence: Bool
    let windowPosition: WindowPosition
    let appearance: SubtitleAppearance
}

// MARK: - App Group Constants
enum AppGroupConstants {
    static let groupIdentifier = "group.com.subtitletranslator"
    static let audioBufferKey = "audioBufferChunks"
    static let subtitleUpdateKey = "subtitleUpdate"
}
