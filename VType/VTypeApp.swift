import SwiftUI

@main
struct VTypeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var state = RuntimeState.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
        } label: {
            Text(state.vietnameseEnabled ? "VI" : "EN")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let inputOwnerDidChange = Notification.Name(
        "com.npv2k1.vtype.inputOwnerDidChange"
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier
            let hasAnotherInstance = NSRunningApplication
                .runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
                .contains { $0.processIdentifier != currentProcessIdentifier }
            guard !hasAnotherInstance else {
                NSApp.terminate(nil)
                return
            }
        }

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(otherVariantClaimedInput(_:)),
            name: Self.inputOwnerDidChange,
            object: nil
        )
        claimInputOwnership()

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Reset prevents a stale word from being replaced in the next app.
            EventTapManager.shared.resetComposition()
            EventTapManager.shared.start()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // TCC may update AXIsProcessTrusted a moment after returning from
        // System Settings. Retrying here avoids requiring an app restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.claimInputOwnership()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        DistributedNotificationCenter.default().removeObserver(self)
        EventTapManager.shared.stop()
    }

    private func claimInputOwnership() {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
            return
        }

        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        DistributedNotificationCenter.default().post(
            name: Self.inputOwnerDidChange,
            object: bundleIdentifier
        )
        EventTapManager.shared.start()
    }

    @objc
    private func otherVariantClaimedInput(_ notification: Notification) {
        guard
            let ownerBundleIdentifier = notification.object as? String,
            ownerBundleIdentifier != Bundle.main.bundleIdentifier
        else {
            return
        }

        EventTapManager.shared.stop()
        EventTapManager.shared.resetComposition()
    }
}
