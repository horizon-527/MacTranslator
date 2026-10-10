import AppKit

if CommandLine.arguments.contains("--smoke-chinese") {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        let input = "你好"
        final class CallRecord: @unchecked Sendable {
            var calls = 0
            var sourceIsChinese = false
            var targetIsEnglish = false
        }
        let record = CallRecord()
        let translator = Translator { text, source, target in
            record.calls += 1
            record.sourceIsChinese = source == Locale.Language(identifier: "zh-Hans")
            record.targetIsEnglish = target == Locale.Language(identifier: "en")
            return "translated: \(text)"
        }
        do {
            let output = try await translator.translate(text: input)
            print("input=\(input); output=\(output); translationCalls=\(record.calls); source=zh-Hans; target=en")
            let passed = output == "translated: 你好" && record.calls == 1 &&
                record.sourceIsChinese && record.targetIsEnglish
            exit(passed ? 0 : 1)
        } catch {
            print("smoke failed: \(error)")
            exit(1)
        }
        semaphore.signal()
    }
    semaphore.wait()
}

if CommandLine.arguments.contains("--smoke-english") {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        let input = "Hello world"
        final class CallCounter: @unchecked Sendable { var value = 0 }
        let counter = CallCounter()
        let translator = Translator { _, _, _ in
            counter.value += 1
            return "unexpected translation"
        }
        do {
            let output = try await translator.translate(text: input)
            print("input=\(input); output=\(output); translationCalls=\(counter.value)")
            exit(output == input && counter.value == 0 ? 0 : 1)
        } catch {
            print("smoke failed: \(error)")
            exit(1)
        }
        semaphore.signal()
    }
    semaphore.wait()
}

// 必须手动创建 NSApplication 实例（SwiftPM 可执行文件不会自动创建）
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// 菜单栏 App，不在 Dock 里显示
app.setActivationPolicy(.accessory)
app.run()
