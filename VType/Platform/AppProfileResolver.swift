import AppKit

struct AppProfile {
    var bundleIdentifier: String?
    var displayName: String
    var isTerminal: Bool
    var aggressiveCodeDetection: Bool
}

struct AppProfileResolver {
    private let terminalBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.github.wez.wezterm"
    ]

    private let developerBundleIDs: Set<String> = [
        "com.apple.dt.Xcode",
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92",
        "com.jetbrains.intellij",
        "com.jetbrains.AppCode",
        "com.jetbrains.CLion"
    ]

    func current() -> AppProfile {
        let app = NSWorkspace.shared.frontmostApplication
        let bundleID = app?.bundleIdentifier
        return AppProfile(
            bundleIdentifier: bundleID,
            displayName: app?.localizedName ?? "Unknown",
            isTerminal: bundleID.map(terminalBundleIDs.contains) ?? false,
            aggressiveCodeDetection: bundleID.map(developerBundleIDs.contains) ?? false
        )
    }
}

