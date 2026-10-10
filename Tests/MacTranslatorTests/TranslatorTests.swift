#if canImport(XCTest)
import XCTest
@testable import MacTranslator

final class TranslatorTests: XCTestCase {
    private final class CallRecorder: @unchecked Sendable {
        var called = false
        var text: String?
    }
    private func assertDirection(_ text: String, source: String, target: String,
                                 file: StaticString = #filePath, line: UInt = #line) {
        let direction = Translator.detectDirection(text)
        XCTAssertEqual(direction.0, source, file: file, line: line)
        XCTAssertEqual(direction.1, target, file: file, line: line)
    }

    func testEnglishInputReturnsOriginalTextWithoutTranslation() async throws {
        let recorder = CallRecorder()
        let translator = Translator { _, _, _ in
            recorder.called = true
            return "unexpected translation"
        }

        let input = "Hello world"
        let output = try await translator.translate(text: input)

        XCTAssertEqual(output, input)
        XCTAssertFalse(recorder.called)
    }

    func testChineseInputUsesInjectedTranslationService() async throws {
        let recorder = CallRecorder()
        let translator = Translator { text, _, _ in
            recorder.text = text
            return "translated"
        }

        let output = try await translator.translate(text: "你好")

        XCTAssertEqual(output, "translated")
        XCTAssertEqual(recorder.text, "你好")
    }

    func testEnglishPunctuationAndNumbersAreEnglish() {
        assertDirection("Hello, WORLD! 123", source: "en", target: "zh-CN")
    }

    func testChineseInputKeepsChineseToEnglishDirection() {
        assertDirection("你好 world", source: "zh-CN", target: "en")
    }

    func testNonEnglishTextStaysOnTranslationPath() {
        assertDirection("こんにちは", source: "unknown", target: "zh-CN")
        assertDirection("123 !?", source: "unknown", target: "zh-CN")
    }

    func testEmptyAndWhitespaceUseTranslationPath() {
        assertDirection("", source: "unknown", target: "zh-CN")
        assertDirection("   \n\t", source: "unknown", target: "zh-CN")
    }
}
#endif
