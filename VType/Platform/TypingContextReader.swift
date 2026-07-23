import ApplicationServices
import Foundation

struct TypingContextReader {
    private let maximumContextLength = 64

    func restorableWordBeforeCaret() -> String? {
        let systemWide = AXUIElementCreateSystemWide()
        guard let element = copyElement(
            attribute: kAXFocusedUIElementAttribute as CFString,
            from: systemWide
        ),
        !isSecure(element),
        let selection = selectedRange(in: element),
        selection.length == 0,
        selection.location > 0
        else { return nil }

        let length = min(maximumContextLength, selection.location)
        var range = CFRange(location: selection.location - length, length: length)
        guard let rangeValue = AXValueCreate(.cfRange, &range) else { return nil }

        var result: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXStringForRangeParameterizedAttribute as CFString,
            rangeValue,
            &result
        ) == .success,
        let precedingText = result as? String
        else { return nil }

        return VietnameseEngine.restorableWord(in: precedingText)
    }

    private func isSecure(_ element: AXUIElement) -> Bool {
        if copyString(attribute: kAXSubroleAttribute as CFString, from: element)
            == "AXSecureTextField" {
            return true
        }

        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element,
            "AXProtectedContent" as CFString,
            &value
        ) == .success,
        let protected = value as? Bool {
            return protected
        }
        return false
    }

    private func selectedRange(in element: AXUIElement) -> CFRange? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &value
        ) == .success,
        let value,
        CFGetTypeID(value) == AXValueGetTypeID()
        else { return nil }

        let rangeValue = value as! AXValue
        guard
        AXValueGetType(rangeValue) == .cfRange
        else { return nil }

        var range = CFRange()
        guard AXValueGetValue(rangeValue, .cfRange, &range) else { return nil }
        return range
    }

    private func copyElement(
        attribute: CFString,
        from element: AXUIElement
    ) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let value
        else { return nil }
        return (value as! AXUIElement)
    }

    private func copyString(
        attribute: CFString,
        from element: AXUIElement
    ) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success
        else { return nil }
        return value as? String
    }
}
