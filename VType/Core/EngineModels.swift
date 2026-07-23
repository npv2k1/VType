import Foundation

public enum EngineAction: Equatable, Sendable {
    case passthrough
    case suppress
    case replace(deleteCount: Int, text: String)
}

public enum BufferSource: String, Equatable, Sendable {
    case active
    case restored
}

public struct EngineTrace: Equatable, Sendable {
    public var key: Character
    public var bufferSource: BufferSource
    public var rawBefore: String
    public var rawAfter: String
    public var renderedBefore: String
    public var renderedAfter: String
    public var tone: String
    public var toneTarget: String
    public var action: EngineAction
    public var isAutorepeat: Bool
}

public struct TypingContext: Equatable, Sendable {
    public var developerMode: Bool
    public var bundleIdentifier: String?
    public var aggressiveCodeDetection: Bool

    public init(
        developerMode: Bool = true,
        bundleIdentifier: String? = nil,
        aggressiveCodeDetection: Bool = false
    ) {
        self.developerMode = developerMode
        self.bundleIdentifier = bundleIdentifier
        self.aggressiveCodeDetection = aggressiveCodeDetection
    }
}
