import Foundation

public enum TokenKind: Equatable, Sendable {
    case naturalLanguage
    case englishOrCode
    case undecided
}

public struct DeveloperContextClassifier: Sendable {
    private let exactWords: Set<String>
    private let codeApps: Set<String>

    public init() {
        exactWords = Set(Self.defaultWords)
        codeApps = Set([
            "com.apple.dt.Xcode",
            "com.microsoft.VSCode",
            "com.todesktop.230313mzl4w4u92",
            "com.jetbrains.intellij",
            "com.jetbrains.AppCode",
            "com.jetbrains.CLion",
            "com.googlecode.iterm2",
            "com.apple.Terminal",
            "dev.warp.Warp-Stable",
            "com.github.wez.wezterm"
        ])
    }

    public func classify(rawToken: String, context: TypingContext) -> TokenKind {
        guard context.developerMode, !rawToken.isEmpty else { return .undecided }

        if rawToken.contains(where: { "_./\\:@#$%{}[]()<>=+-*|&!?0123456789".contains($0) }) {
            return .englishOrCode
        }

        let lower = rawToken.lowercased()
        if exactWords.contains(lower) {
            return .englishOrCode
        }

        if hasMixedCaseIdentifier(rawToken) || rawToken.count > 40 {
            return .englishOrCode
        }

        let isCodeApp = context.bundleIdentifier.map(codeApps.contains) ?? false
        if (isCodeApp || context.aggressiveCodeDetection) && looksLikeCodeWord(lower) {
            return .englishOrCode
        }

        if Self.commonVietnameseRawWords.contains(lower) {
            return .naturalLanguage
        }

        return .undecided
    }

    private func hasMixedCaseIdentifier(_ value: String) -> Bool {
        let chars = Array(value)
        guard chars.count > 1 else { return false }
        return chars.dropFirst().contains(where: \.isUppercase)
            && chars.contains(where: \.isLowercase)
    }

    private func looksLikeCodeWord(_ value: String) -> Bool {
        let codeSuffixes = [
            "service", "controller", "repository", "factory", "manager",
            "provider", "handler", "request", "response", "config", "client",
            "server", "module", "model", "entity", "schema", "interface"
        ]
        return codeSuffixes.contains { value.hasSuffix($0) }
    }

    private static let commonVietnameseRawWords: Set<String> = [
        "toi", "tooi", "ban", "bajn", "dang", "ddang", "khong", "khoong",
        "mot", "moojt", "nguoi", "nguowif", "viet", "vieetj", "tieng",
        "tieengs", "duoc", "dduowjc", "nay", "nafy", "lam", "laf"
    ]

    private static let defaultWords = [
        "any", "api", "app", "array", "as", "async", "await", "backend",
        "bool", "boolean", "branch", "browser",
        "buffer", "build", "cache", "callback", "class", "client", "cloud",
        "code", "commit", "config", "const", "constant", "container", "context",
        "controller", "cursor", "database", "debug", "decode", "docker",
        "document", "double", "else", "email", "encode", "endpoint", "engine",
        "entity", "enum", "error", "event", "extends", "false", "feature",
        "file", "filter", "float", "for", "from", "frontend", "func", "function",
        "generic", "github", "handler", "header", "hook", "html", "http",
        "https", "if", "implements", "import", "index", "input", "int",
        "interface", "is", "item", "javascript", "join", "json",
        "key", "keyboard", "kubernetes", "library", "linux", "local", "localhost",
        "logging", "loop", "macos", "main", "manager", "map", "memory", "merge", "method",
        "middleware", "model", "module", "mongodb", "nestjs", "network", "node",
        "never", "null", "object", "offset", "option", "output", "package",
        "password", "path", "private", "protected", "protocol", "public",
        "payload", "plugin", "port", "process", "project", "promise", "property",
        "provider", "queue", "react", "readme", "redis", "release", "repository",
        "request", "response", "return", "route", "router", "runtime", "schema", "script",
        "server", "service", "session", "settings", "source", "string", "swift",
        "swiftui", "switch", "system", "terminal", "test", "this", "throw",
        "throws", "token", "true", "try", "typescript", "undefined", "unicode",
        "unit", "unknown", "update", "url", "user", "value", "var", "variable",
        "version", "view", "void", "vscode", "web", "where", "while",
        "workspace", "xcode"
    ]
}
