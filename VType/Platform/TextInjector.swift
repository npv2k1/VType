import CoreGraphics

final class TextInjector {
    static let syntheticMarker: Int64 = 0x5654595045

    private let source = CGEventSource(stateID: .hidSystemState)

    @discardableResult
    func replace(deleteCount: Int, with text: String) -> Bool {
        guard let source else { return false }

        // Build everything before posting. If event creation fails, the physical
        // trigger key can still pass through without partially deleting a word.
        var events: [CGEvent] = []
        for _ in 0..<deleteCount {
            guard let down = makeKey(source: source, keyCode: 51, down: true),
                  let up = makeKey(source: source, keyCode: 51, down: false)
            else { return false }
            events.append(down)
            events.append(up)
        }

        if !text.isEmpty {
            let utf16 = Array(text.utf16)
            guard let down = makeUnicodeEvent(source: source, text: utf16, down: true),
                  let up = makeUnicodeEvent(source: source, text: utf16, down: false)
            else { return false }
            events.append(down)
            events.append(up)
        }

        events.forEach { $0.post(tap: .cghidEventTap) }
        return true
    }

    private func makeKey(
        source: CGEventSource,
        keyCode: CGKeyCode,
        down: Bool
    ) -> CGEvent? {
        guard let event = CGEvent(
            keyboardEventSource: source,
            virtualKey: keyCode,
            keyDown: down
        ) else { return nil }
        event.setIntegerValueField(.eventSourceUserData, value: Self.syntheticMarker)
        return event
    }

    private func makeUnicodeEvent(
        source: CGEventSource,
        text: [UniChar],
        down: Bool
    ) -> CGEvent? {
        guard let event = CGEvent(
            keyboardEventSource: source,
            virtualKey: 0,
            keyDown: down
        ) else { return nil }
        event.setIntegerValueField(.eventSourceUserData, value: Self.syntheticMarker)
        event.keyboardSetUnicodeString(stringLength: text.count, unicodeString: text)
        return event
    }
}
