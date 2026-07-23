import Foundation

public final class VietnameseEngine {
    public private(set) var rawBuffer = ""
    public private(set) var renderedBuffer = ""

    private let composer: TelexComposer
    private let classifier: DeveloperContextClassifier

    public init(
        composer: TelexComposer = TelexComposer(),
        classifier: DeveloperContextClassifier = DeveloperContextClassifier()
    ) {
        self.composer = composer
        self.classifier = classifier
    }

    public func process(character: Character, context: TypingContext) -> EngineAction {
        guard character.isLetter, character.isASCII else {
            reset()
            return .passthrough
        }

        let previousRendered = renderedBuffer
        rawBuffer.append(character)

        let classification = classifier.classify(rawToken: rawBuffer, context: context)
        let nextRendered: String
        if classification == .englishOrCode {
            nextRendered = rawBuffer
        } else {
            nextRendered = composer.compose(rawBuffer)
        }
        renderedBuffer = nextRendered

        if nextRendered == previousRendered + String(character) {
            return .passthrough
        }
        return .replace(deleteCount: previousRendered.count, text: nextRendered)
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
    }
}

