import Foundation

final class RuntimeState: ObservableObject {
    static let shared = RuntimeState()

    static let stateDidChange = Notification.Name("VType.RuntimeStateDidChange")

    @Published private(set) var isRunning = false
    @Published private(set) var vietnameseEnabled = true
    @Published var developerMode: Bool {
        didSet { UserDefaults.standard.set(developerMode, forKey: Keys.developerMode) }
    }
    @Published var disableInTerminals: Bool {
        didSet { UserDefaults.standard.set(disableInTerminals, forKey: Keys.disableInTerminals) }
    }
    @Published private(set) var permissionGranted = false
    @Published private(set) var activeAppName = "—"
    @Published private(set) var diagnosticMessage = "Đang khởi tạo…"
    @Published private(set) var receivedEventCount: UInt64 = 0

    private enum Keys {
        static let developerMode = "developerMode"
        static let disableInTerminals = "disableInTerminals"
    }

    private init() {
        UserDefaults.standard.register(defaults: [
            Keys.developerMode: true,
            Keys.disableInTerminals: false
        ])
        developerMode = UserDefaults.standard.bool(forKey: Keys.developerMode)
        disableInTerminals = UserDefaults.standard.bool(forKey: Keys.disableInTerminals)

        NotificationCenter.default.addObserver(
            forName: Self.stateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self, let snapshot = note.object as? RuntimeSnapshot else { return }
            self.isRunning = snapshot.isRunning
            self.vietnameseEnabled = snapshot.vietnameseEnabled
            self.permissionGranted = snapshot.permissionGranted
            self.activeAppName = snapshot.activeAppName
            self.diagnosticMessage = snapshot.diagnosticMessage
            self.receivedEventCount = snapshot.receivedEventCount
        }
    }
}

struct RuntimeSnapshot {
    var isRunning: Bool
    var vietnameseEnabled: Bool
    var permissionGranted: Bool
    var activeAppName: String
    var diagnosticMessage: String
    var receivedEventCount: UInt64
}
