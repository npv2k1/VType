import XCTest
#if canImport(VTypeCore)
@testable import VTypeCore
#else
@testable import VType
#endif

final class VietnameseEngineTests: XCTestCase {
    func testVietnameseTyping() {
        let engine = VietnameseEngine()
        let context = TypingContext(developerMode: true)
        var action: EngineAction = .passthrough

        for character in "tieengs" {
            action = engine.process(character: character, context: context)
        }

        XCTAssertEqual(engine.rawBuffer, "tieengs")
        XCTAssertEqual(engine.renderedBuffer, "tiếng")
        XCTAssertEqual(action, .replace(deleteCount: 5, text: "tiếng"))
    }

    func testRestoresEnglishWordAfterTemporaryTelexTransform() {
        let engine = VietnameseEngine()
        let context = TypingContext(developerMode: true)

        for character in "process" {
            _ = engine.process(character: character, context: context)
        }

        XCTAssertEqual(engine.renderedBuffer, "process")
    }

    func testCodeIdentifierIsPreserved() {
        let classifier = DeveloperContextClassifier()
        let context = TypingContext(developerMode: true)
        XCTAssertEqual(
            classifier.classify(rawToken: "UserService", context: context),
            .englishOrCode
        )
    }

    func testResetOnBoundary() {
        let engine = VietnameseEngine()
        _ = engine.process(character: "a", context: TypingContext())
        _ = engine.process(character: "a", context: TypingContext())
        XCTAssertEqual(engine.renderedBuffer, "â")

        _ = engine.process(character: " ", context: TypingContext())
        XCTAssertTrue(engine.rawBuffer.isEmpty)
    }

    func testAppliesDotToneToActiveBuffer() {
        let engine = VietnameseEngine()
        let context = TypingContext(developerMode: true)

        for character in "ddoong" {
            _ = engine.process(character: character, context: context)
        }
        XCTAssertEqual(engine.rawBuffer, "ddoong")
        XCTAssertEqual(engine.renderedBuffer, "đông")

        let action = engine.process(character: "j", context: context)

        XCTAssertEqual(engine.rawBuffer, "ddoongj")
        XCTAssertEqual(engine.renderedBuffer, "động")
        XCTAssertEqual(action, .replace(deleteCount: 4, text: "động"))
        XCTAssertEqual(engine.lastTrace?.bufferSource, .active)
        XCTAssertEqual(engine.lastTrace?.rawBefore, "ddoong")
        XCTAssertEqual(engine.lastTrace?.renderedBefore, "đông")
        XCTAssertEqual(engine.lastTrace?.tone, "dot")
        XCTAssertEqual(engine.lastTrace?.toneTarget, "ô")
    }

    func testRestoresVietnameseWordBeforeApplyingTone() {
        let engine = VietnameseEngine()
        let context = TypingContext(developerMode: true)

        XCTAssertTrue(engine.seed(renderedWord: "đông"))
        let action = engine.process(character: "j", context: context)

        XCTAssertEqual(engine.rawBuffer, "đôngj")
        XCTAssertEqual(engine.renderedBuffer, "động")
        XCTAssertEqual(action, .replace(deleteCount: 4, text: "động"))
        XCTAssertEqual(engine.lastTrace?.bufferSource, .restored)
    }

    func testDoesNotRestoreEnglishWord() {
        let engine = VietnameseEngine()

        XCTAssertFalse(engine.seed(renderedWord: "process"))
        XCTAssertTrue(engine.rawBuffer.isEmpty)
        XCTAssertNil(VietnameseEngine.restorableWord(in: "call process"))
        XCTAssertEqual(
            VietnameseEngine.restorableWord(in: "trước đó đông"),
            "đông"
        )
    }

    func testSuppressesAutorepeatedToneKeyDuringComposition() {
        let engine = VietnameseEngine()
        let context = TypingContext(developerMode: true)

        for character in "ddoongj" {
            _ = engine.process(character: character, context: context)
        }

        let action = engine.process(
            character: "j",
            context: context,
            isAutorepeat: true
        )

        XCTAssertEqual(action, .suppress)
        XCTAssertEqual(engine.rawBuffer, "ddoongj")
        XCTAssertEqual(engine.renderedBuffer, "động")
        XCTAssertEqual(engine.lastTrace?.isAutorepeat, true)
    }
}
