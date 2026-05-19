import NaturalLanguage
import Combine

// MARK: - Translation Engine
/// Uses Apple NLTranslator for on-device translation between Chinese and English.
/// Falls back to a built-in dictionary-based translation when NLTranslator is unavailable.
final class TranslationEngine: ObservableObject {
    static let shared = TranslationEngine()

    @Published var isTranslating = false
    @Published var latestTranslation: String = ""

    private let queue = DispatchQueue(label: "com.subtitle.translation", qos: .userInitiated)

    // Language code mapping
    private let languageMap: [SubtitleLanguage: NLLanguage] = [
        .chinese: .chinese,
        .english: .english
    ]

    private init() {}

    /// Translate text from source language to target language
    func translate(
        text: String,
        from source: SubtitleLanguage,
        to target: SubtitleLanguage,
        completion: @escaping (Result<String, TranslationError>) -> Void
    ) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            completion(.failure(.emptyInput))
            return
        }

        queue.async { [weak self] in
            guard let self = self else { return }

            // Attempt on-device translation via NLTranslator
            let sourceLang = self.languageMap[source] ?? .chinese
            let targetLang = self.languageMap[target] ?? .english

            // Build translator
            if let translator = NLTranslator(from: sourceLang, to: targetLang) {
                let group = DispatchGroup()
                group.enter()
                var translated: String?
                var translateError: Error?

                translator.translate(text) { result, error in
                    translated = result
                    translateError = error
                    group.leave()
                }
                group.wait()

                if let translated = translated, !translated.isEmpty {
                    DispatchQueue.main.async { self.latestTranslation = translated }
                    completion(.success(translated))
                    return
                }
                if let error = translateError {
                    print("[Translation] NLTranslator error: \(error.localizedDescription)")
                }
            }

            // Fallback: built-in dictionary
            let fallback = self.fallbackTranslate(text: text, from: source, to: target)
            DispatchQueue.main.async { self.latestTranslation = fallback }
            completion(.success(fallback))
        }
    }

    /// Built-in fallback dictionary-based translation
    private func fallbackTranslate(text: String, from source: SubtitleLanguage, to target: SubtitleLanguage) -> String {
        // Chinese → English or English → Chinese
        switch (source, target) {
        case (.chinese, .english):
            return translateChineseToEnglish(text)
        case (.english, .chinese):
            return translateEnglishToChinese(text)
        default:
            return text
        }
    }

    // MARK: - Built-in Dictionary (Common Movie/Conversation Phrases)

    private let chineseToEnglishDict: [String: String] = [
        "你好": "Hello",
        "谢谢": "Thank you",
        "对不起": "I'm sorry",
        "再见": "Goodbye",
        "好的": "Okay",
        "不": "No",
        "是": "Yes",
        "我": "I",
        "你": "You",
        "他": "He",
        "她": "She",
        "我们": "We",
        "他们": "They",
        "这": "This",
        "那": "That",
        "什么": "What",
        "哪里": "Where",
        "为什么": "Why",
        "怎么": "How",
        "什么时候": "When",
        "谁": "Who",
        "可以": "Can",
        "不能": "Cannot",
        "知道": "Know",
        "不知道": "Don't know",
        "明白": "Understand",
        "爱": "Love",
        "恨": "Hate",
        "喜欢": "Like",
        "想要": "Want",
        "需要": "Need",
        "给我": "Give me",
        "过来": "Come here",
        "走开": "Go away",
        "小心": "Be careful",
        "快点": "Hurry up",
        "等一下": "Wait",
        "太好了": "Great",
        "天啊": "Oh my god",
        "救命": "Help",
        "没事": "It's fine",
        "没关系": "No problem",
        "当然": "Of course",
        "绝对": "Absolutely",
        "也许": "Maybe",
        "不可能": "Impossible",
        "相信我": "Trust me",
        "别担心": "Don't worry",
        "我爱你": "I love you",
        "我想你": "I miss you",
        "对不起": "I'm sorry",
        "帮帮我": "Help me",
        "别走": "Don't go",
        "回来": "Come back",
        "听着": "Listen",
        "看着": "Look",
        "安静": "Quiet",
        "闭嘴": "Shut up",
        "你说什么": "What did you say",
        "我不知道": "I don't know",
        "这是真的": "It's true",
        "你疯了吗": "Are you crazy",
        "让我想想": "Let me think",
    ]

    private let englishToChineseDict: [String: String] = [
        "hello": "你好",
        "thank you": "谢谢",
        "sorry": "对不起",
        "goodbye": "再见",
        "okay": "好的",
        "no": "不",
        "yes": "是",
        "i": "我",
        "you": "你",
        "he": "他",
        "she": "她",
        "we": "我们",
        "they": "他们",
        "this": "这",
        "that": "那",
        "what": "什么",
        "where": "哪里",
        "why": "为什么",
        "how": "怎么",
        "when": "什么时候",
        "who": "谁",
        "can": "可以",
        "cannot": "不能",
        "know": "知道",
        "don't know": "不知道",
        "understand": "明白",
        "love": "爱",
        "hate": "恨",
        "like": "喜欢",
        "want": "想要",
        "need": "需要",
        "give me": "给我",
        "come here": "过来",
        "go away": "走开",
        "be careful": "小心",
        "hurry up": "快点",
        "wait": "等一下",
        "great": "太好了",
        "oh my god": "天啊",
        "help": "救命",
        "it's fine": "没事",
        "no problem": "没关系",
        "of course": "当然",
        "absolutely": "绝对",
        "maybe": "也许",
        "impossible": "不可能",
        "trust me": "相信我",
        "don't worry": "别担心",
        "i love you": "我爱你",
        "i miss you": "我想你",
        "help me": "帮帮我",
        "don't go": "别走",
        "come back": "回来",
        "listen": "听着",
        "look": "看着",
        "quiet": "安静",
        "shut up": "闭嘴",
        "what did you say": "你说什么",
        "i don't know": "我不知道",
        "it's true": "这是真的",
        "are you crazy": "你疯了吗",
        "let me think": "让我想想",
    ]

    private func translateChineseToEnglish(_ text: String) -> String {
        // Try exact match first
        if let exact = chineseToEnglishDict[text] {
            return exact
        }
        // Try partial matching
        var result = text
        for (cn, en) in chineseToEnglishDict {
            if text.contains(cn) {
                result = result.replacingOccurrences(of: cn, with: en)
            }
        }
        // If no matches found, return transliteration hint
        if result == text {
            return "[翻译: \(text)]"
        }
        return result
    }

    private func translateEnglishToChinese(_ text: String) -> String {
        let lowercased = text.lowercased()
        if let exact = englishToChineseDict[lowercased] {
            return exact
        }
        var result = lowercased
        for (en, cn) in englishToChineseDict {
            if lowercased.contains(en) {
                result = result.replacingOccurrences(of: en, with: cn)
            }
        }
        if result == lowercased {
            return "[Translation: \(text)]"
        }
        return result
    }
}

// MARK: - Translation Errors
enum TranslationError: LocalizedError {
    case emptyInput
    case translatorUnavailable
    case translationFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyInput: return "输入文本为空"
        case .translatorUnavailable: return "翻译引擎不可用"
        case .translationFailed(let msg): return "翻译失败: \(msg)"
        }
    }
}
