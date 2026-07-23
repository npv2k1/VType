import Foundation

public final class VietnameseEngine {
    public private(set) var rawBuffer = ""
    public private(set) var renderedBuffer = ""
    public private(set) var lastTrace: EngineTrace?

    private let composer: TelexComposer
    private let classifier: DeveloperContextClassifier
    private var nextBufferSource: BufferSource = .active

    public init(
        composer: TelexComposer = TelexComposer(),
        classifier: DeveloperContextClassifier = DeveloperContextClassifier()
    ) {
        self.composer = composer
        self.classifier = classifier
    }

    public func process(
        character: Character,
        context: TypingContext,
        isAutorepeat: Bool = false
    ) -> EngineAction {
        let rawBefore = rawBuffer
        let previousRendered = renderedBuffer
        let source = nextBufferSource
        nextBufferSource = .active

        if isAutorepeat, Self.isToneKey(character), !rawBuffer.isEmpty {
            let action = EngineAction.suppress
            lastTrace = makeTrace(
                key: character,
                source: source,
                rawBefore: rawBefore,
                renderedBefore: previousRendered,
                action: action,
                isAutorepeat: true
            )
            return action
        }

        guard character.isLetter, character.isASCII else {
            reset()
            return .passthrough
        }

        rawBuffer.append(character)

        let classification = classifier.classify(rawToken: rawBuffer, context: context)
        let nextRendered: String
        if classification == .englishOrCode {
            nextRendered = rawBuffer
        } else {
            nextRendered = composer.compose(rawBuffer)
        }
        renderedBuffer = nextRendered

        let action: EngineAction
        if nextRendered == previousRendered + String(character) {
            action = .passthrough
        } else {
            action = .replace(deleteCount: previousRendered.count, text: nextRendered)
        }
        lastTrace = makeTrace(
            key: character,
            source: source,
            rawBefore: rawBefore,
            renderedBefore: previousRendered,
            action: action,
            isAutorepeat: isAutorepeat
        )
        return action
    }

    @discardableResult
    public func seed(renderedWord: String) -> Bool {
        guard rawBuffer.isEmpty,
              !renderedWord.isEmpty,
              renderedWord.allSatisfy(\.isLetter),
              Self.containsVietnameseSignal(renderedWord)
        else { return false }

        rawBuffer = renderedWord
        renderedBuffer = renderedWord
        nextBufferSource = .restored
        return true
    }

    public func handleBackspace() {
        guard !renderedBuffer.isEmpty else {
            reset()
            return
        }
        rawBuffer = ""
        renderedBuffer = ""
    }

    public func reset() {
        rawBuffer = ""
        renderedBuffer = ""
        nextBufferSource = .active
    }

    public static func isToneKey(_ character: Character) -> Bool {
        character.isASCII && "sfrxj".contains(Character(character.lowercased()))
    }

    public static func containsVietnameseSignal(_ word: String) -> Bool {
        word.lowercased().contains {
            "ăâđêôơưáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ"
                .contains($0)
        }
    }

    public static func restorableWord(in precedingText: String) -> String? {
        let start = precedingText.lastIndex(where: { !$0.isLetter })
            .map(precedingText.index(after:)) ?? precedingText.startIndex
        let word = String(precedingText[start...])
        return containsVietnameseSignal(word) ? word : nil
    }

    private func makeTrace(
        key: Character,
        source: BufferSource,
        rawBefore: String,
        renderedBefore: String,
        action: EngineAction,
        isAutorepeat: Bool
    ) -> EngineTrace {
        EngineTrace(
            key: key,
            bufferSource: source,
            rawBefore: rawBefore,
            rawAfter: rawBuffer,
            renderedBefore: renderedBefore,
            renderedAfter: renderedBuffer,
            tone: Self.toneName(for: key),
            toneTarget: Self.changedCharacter(
                before: renderedBefore,
                after: renderedBuffer
            ),
            action: action,
            isAutorepeat: isAutorepeat
        )
    }

    private static func toneName(for character: Character) -> String {
        switch Character(character.lowercased()) {
        case "s": return "acute"
        case "f": return "grave"
        case "r": return "hook"
        case "x": return "tilde"
        case "j": return "dot"
        default: return "none"
        }
    }

    private static func changedCharacter(before: String, after: String) -> String {
        for (old, new) in zip(before, after) where old != new {
            return String(old)
        }
        return "—"
    }
}
