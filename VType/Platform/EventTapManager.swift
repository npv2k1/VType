import AppKit
import CoreGraphics
import OSLog

final class EventTapManager {
    static let shared = EventTapManager()

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "dev.vtype.app",
        category: "EventTap"
    )

    private let engine = VietnameseEngine()
    private let injector = TextInjector()
    private let profileResolver = AppProfileResolver()
    private let contextReader = TypingContextReader()
    private let lock = NSLock()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var vietnameseEnabled = true
    private var running = false
    private var diagnosticMessage = "EventTap chưa được khởi động."
    private var debugTrace = "Chưa có phím nào được xử lý."
    private var receivedEventCount: UInt64 = 0

    private init() {}

    func start(promptForPermission: Bool = false) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.start(promptForPermission: promptForPermission)
            }
            return
        }

        if promptForPermission {
            AccessibilityPermission.request()
        }
        guard AccessibilityPermission.isGranted else {
            updateRuntime(
                running: false,
                diagnostic: "Chưa có quyền Accessibility cho đúng bản VType đang chạy."
            )
            Self.logger.notice("Accessibility permission is not granted")
            publishState()
            return
        }

        if let eventTap {
            if !CGEvent.tapIsEnabled(tap: eventTap) {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            let enabled = CGEvent.tapIsEnabled(tap: eventTap)
            updateRuntime(
                running: enabled,
                diagnostic: enabled
                    ? activeDiagnosticMessage
                    : "EventTap tồn tại nhưng không thể bật lại. Hãy bấm “Khởi động lại EventTap”."
            )
            publishState()
            return
        }

        // The two tap-disabled values are callback notifications, not normal
        // event-mask bits (their raw values are UInt32.max - 1 / UInt32.max).
        // Core Graphics delivers them automatically when the tap is disabled.
        let mask = CGEventMask(1) << CGEventType.keyDown.rawValue

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: Self.callback,
            userInfo: refcon
        ) else {
            updateRuntime(
                running: false,
                diagnostic: "Không tạo được EventTap dù Accessibility đã cấp. Hãy tắt/bật lại quyền cho VType rồi khởi động lại app."
            )
            Self.logger.error("CGEvent.tapCreate returned nil")
            publishState()
            return
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            updateRuntime(
                running: false,
                diagnostic: "Không tạo được RunLoop source cho EventTap."
            )
            Self.logger.error("CFMachPortCreateRunLoopSource returned nil")
            publishState()
            return
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        let enabled = CGEvent.tapIsEnabled(tap: tap)
        updateRuntime(
            running: enabled,
            diagnostic: enabled
                ? "EventTap đang chạy. Hãy gõ thử; bộ đếm sự kiện phải tăng."
                : "EventTap đã tạo nhưng macOS không cho phép bật."
        )
        if enabled {
            Self.logger.notice("EventTap started")
        } else {
            Self.logger.error("EventTap was created but is disabled")
        }
        publishState()
    }

    func stop() {
        teardownEventTap()
        engine.reset()
        updateRuntime(running: false, diagnostic: "EventTap đã dừng.")
        publishState()
    }

    func restart() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.restart() }
            return
        }
        teardownEventTap()
        engine.reset()
        lock.locked { receivedEventCount = 0 }
        Self.logger.notice("Restarting EventTap")
        start()
    }

    func toggleVietnamese() {
        lock.locked { vietnameseEnabled.toggle() }
        engine.reset()
        publishState()
    }

    func setVietnamese(_ value: Bool) {
        lock.locked { vietnameseEnabled = value }
        engine.reset()
        publishState()
    }

    func resetComposition() {
        engine.reset()
    }

    private static let callback: CGEventTapCallBack = {
        proxy, type, event, userInfo in
        guard let userInfo else { return Unmanaged.passUnretained(event) }
        let manager = Unmanaged<EventTapManager>.fromOpaque(userInfo).takeUnretainedValue()
        return manager.handle(proxy: proxy, type: type, event: event)
    }

    private func handle(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            engine.reset()
            let enabled = eventTap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false
            updateRuntime(
                running: enabled,
                diagnostic: enabled
                    ? "EventTap từng bị macOS tạm dừng và đã được bật lại."
                    : "EventTap bị macOS vô hiệu hóa và không bật lại được."
            )
            if enabled {
                Self.logger.warning("EventTap was disabled by the system and re-enabled")
            } else {
                Self.logger.error("EventTap was disabled by the system and could not be re-enabled")
            }
            publishState()
            return Unmanaged.passUnretained(event)
        }

        if event.getIntegerValueField(.eventSourceUserData) == TextInjector.syntheticMarker {
            return Unmanaged.passUnretained(event)
        }

        let eventCount = lock.locked {
            receivedEventCount += 1
            return receivedEventCount
        }
        if eventCount == 1 {
            updateRuntime(
                running: true,
                diagnostic: "EventTap hoạt động: đã nhận được sự kiện bàn phím."
            )
            Self.logger.notice("Received the first physical keyboard event")
            publishState()
        } else if eventCount.isMultiple(of: 25) {
            publishState()
        }

        let flags = event.flags
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

        if keyCode == 49,
           flags.contains(.maskControl),
           flags.contains(.maskAlternate),
           !flags.contains(.maskCommand) {
            toggleVietnamese()
            return nil
        }

        let profile = profileResolver.current()
        let settings = UserDefaults.standard
        let enabled = lock.locked { vietnameseEnabled }
        guard enabled,
              !flags.contains(.maskCommand),
              !flags.contains(.maskControl),
              !flags.contains(.maskAlternate),
              !(profile.isTerminal && settings.bool(forKey: "disableInTerminals"))
        else {
            engine.reset()
            return Unmanaged.passUnretained(event)
        }

        if keyCode == 51 {
            engine.handleBackspace()
            return Unmanaged.passUnretained(event)
        }

        if Self.resetKeyCodes.contains(keyCode) {
            engine.reset()
            return Unmanaged.passUnretained(event)
        }

        guard let character = event.unicodeCharacter else {
            engine.reset()
            return Unmanaged.passUnretained(event)
        }

        let isAutorepeat =
            event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        if engine.rawBuffer.isEmpty,
           VietnameseEngine.isToneKey(character),
           !isAutorepeat,
           let word = contextReader.restorableWordBeforeCaret() {
            _ = engine.seed(renderedWord: word)
        }

        let context = TypingContext(
            developerMode: settings.bool(forKey: "developerMode"),
            bundleIdentifier: profile.bundleIdentifier,
            aggressiveCodeDetection: profile.aggressiveCodeDetection
        )
        let action = engine.process(
            character: character,
            context: context,
            isAutorepeat: isAutorepeat
        )

        switch action {
        case .passthrough:
            updateDebugTrace(injected: false)
            publishState(activeAppName: profile.displayName)
            return Unmanaged.passUnretained(event)
        case .suppress:
            updateDebugTrace(injected: false)
            publishState(activeAppName: profile.displayName)
            return nil
        case let .replace(deleteCount, text):
            if injector.replace(deleteCount: deleteCount, with: text) {
                updateDebugTrace(injected: true)
                publishState(activeAppName: profile.displayName)
                return nil
            }
            engine.reset()
            updateDebugTrace(injected: false)
            updateRuntime(
                running: true,
                diagnostic: "EventTap nhận được phím nhưng không tạo được sự kiện chèn Unicode."
            )
            Self.logger.error("Failed to create synthetic replacement events")
            publishState(activeAppName: profile.displayName)
            return Unmanaged.passUnretained(event)
        }
    }

    private var activeDiagnosticMessage: String {
        lock.locked {
            receivedEventCount == 0
                ? "EventTap đang chạy. Hãy gõ thử; bộ đếm sự kiện phải tăng."
                : "EventTap hoạt động: đã nhận \(receivedEventCount) sự kiện bàn phím."
        }
    }

    private func teardownEventTap() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        runLoopSource = nil
        eventTap = nil
    }

    private func updateRuntime(running: Bool, diagnostic: String) {
        lock.locked {
            self.running = running
            diagnosticMessage = diagnostic
        }
    }

    private func updateDebugTrace(injected: Bool) {
        guard let trace = engine.lastTrace else { return }
        let action: String
        switch trace.action {
        case .passthrough:
            action = "passthrough"
        case .suppress:
            action = "suppress"
        case let .replace(deleteCount, text):
            action = "replace(\(deleteCount), \"\(text)\")"
        }

        let value = """
        Key              : \(trace.key)
        Buffer source    : \(trace.bufferSource.rawValue)
        Raw before       : \(trace.rawBefore)
        Raw after        : \(trace.rawAfter)
        Rendered before  : \(trace.renderedBefore)
        Rendered after   : \(trace.renderedAfter)
        Tone             : \(trace.tone)
        Tone target      : \(trace.toneTarget)
        Action           : \(action)
        Autorepeat       : \(trace.isAutorepeat)
        Injected         : \(injected)
        """
        lock.locked { debugTrace = value }
    }

    private func publishState(activeAppName: String? = nil) {
        let snapshot = lock.locked {
            RuntimeSnapshot(
                isRunning: running,
                vietnameseEnabled: vietnameseEnabled,
                permissionGranted: AccessibilityPermission.isGranted,
                activeAppName: activeAppName ?? NSWorkspace.shared.frontmostApplication?.localizedName ?? "—",
                diagnosticMessage: diagnosticMessage,
                receivedEventCount: receivedEventCount,
                debugTrace: debugTrace
            )
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: RuntimeState.stateDidChange,
                object: snapshot
            )
        }
    }

    private static let resetKeyCodes: Set<CGKeyCode> = [
        36, 48, 49, 53, 76, 115, 116, 117, 119, 121, 123, 124, 125, 126
    ]
}

private extension CGEvent {
    var unicodeCharacter: Character? {
        var length = 0
        keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)
        guard length > 0 else { return nil }

        var buffer = [UniChar](repeating: 0, count: length)
        keyboardGetUnicodeString(
            maxStringLength: length,
            actualStringLength: &length,
            unicodeString: &buffer
        )
        guard let value = String(utf16CodeUnits: buffer, count: length).first else {
            return nil
        }
        return value
    }
}

private extension NSLock {
    func locked<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
