import Foundation

enum TranslatorError: LocalizedError {
    case unavailable
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .unavailable: return "系统翻译不可用（需要 macOS 15+）"
        case .emptyResult: return "翻译结果为空"
        }
    }
}

public final class Translator {
    public typealias TranslationHandler = @Sendable (
        String, Locale.Language?, Locale.Language
    ) async throws -> String

    static let shared = Translator { text, source, target in
        guard #available(macOS 15.0, *) else {
            throw TranslatorError.unavailable
        }
        return try await SystemTranslator.shared.translate(
            text: text, source: source, target: target
        )
    }

    private let translationHandler: TranslationHandler

    public init(translationHandler: @escaping TranslationHandler) {
        self.translationHandler = translationHandler
    }

    /// 只用 macOS 系统翻译（本地）。自动判向：中文 → 英文，其他 → 中文
    public func translate(text: String) async throws -> String {
        let (sl, tl) = Self.detectDirection(text)
        if sl == "en" {
            return text
        }
        guard #available(macOS 15.0, *) else {
            throw TranslatorError.unavailable
        }
        let sourceLang: Locale.Language? = sl == "zh-CN" ? Locale.Language(identifier: "zh-Hans") : nil
        let targetLang = Locale.Language(identifier: tl == "en" ? "en" : "zh-Hans")
        return try await withTimeout(seconds: 8) {
            try await self.translationHandler(text, sourceLang, targetLang)
        }
    }

    static func detectDirection(_ text: String) -> (String, String) {
        var hasEnglishLetter = false
        for scalar in text.unicodeScalars {
            if (0x4E00...0x9FFF).contains(scalar.value) ||
               (0x3400...0x4DBF).contains(scalar.value) {
                return ("zh-CN", "en")
            }
            if (0x41...0x5A).contains(scalar.value) ||
               (0x61...0x7A).contains(scalar.value) {
                hasEnglishLetter = true
            } else if CharacterSet.letters.contains(scalar) {
                return ("unknown", "zh-CN")
            }
        }
        return hasEnglishLetter ? ("en", "zh-CN") : ("unknown", "zh-CN")
    }
}
