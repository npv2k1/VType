import Foundation

public enum EngineAction: Equatable, Sendable {
    case passthrough
    case replace(deleteCount: Int, text: String)
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

