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
    func applicationDidFinishLaunching(_ notification: Notification) {
        EventTapManager.shared.start()
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
            EventTapManager.shared.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        EventTapManager.shared.stop()
    }
}
