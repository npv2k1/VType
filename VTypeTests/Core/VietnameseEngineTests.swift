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
}
