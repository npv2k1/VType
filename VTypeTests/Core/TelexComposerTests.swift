import XCTest
#if canImport(VTypeCore)
@testable import VTypeCore
#else
@testable import VType
#endif

final class TelexComposerTests: XCTestCase {
    private let composer = TelexComposer()

    func testCommonTelexWords() {
        let cases = [
            "tooi": "tôi",
            "tieengs": "tiếng",
            "Vieetj": "Việt",
            "dduowngf": "đường",
            "ddaau": "đâu",
            "nguowif": "người",
            "hoas": "hóa",
            "thuyr": "thủy",
            "quas": "quá",
            "gias": "giá"
        ]

        for (raw, expected) in cases {
            XCTAssertEqual(composer.compose(raw), expected, "Failed: \(raw)")
        }
    }

    func testRemoveMarksWithZ() {
        XCTAssertEqual(composer.compose("tieengsz"), "tieng")
    }

    func testDotToneTargetsMarkedVowel() {
        XCTAssertEqual(composer.compose("ddoongj"), "động")
        XCTAssertEqual(composer.compose("đôngj"), "động")
    }
}
