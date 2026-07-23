import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var state = RuntimeState.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.vietnameseEnabled ? "Tiếng Việt" : "English")
                        .font(.headline)
                    Text(state.isRunning ? "Đang hoạt động" : "Chưa hoạt động")
                        .font(.caption)
                        .foregroundStyle(state.isRunning ? .green : .orange)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { state.vietnameseEnabled },
                    set: { EventTapManager.shared.setVietnamese($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            Divider()

            if !state.permissionGranted {
                Button("Cấp quyền Accessibility") {
                    AccessibilityPermission.request()
                    AccessibilityPermission.openSystemSettings()
                }
            } else if !state.isRunning {
                Button("Khởi động bộ gõ") {
                    EventTapManager.shared.start()
                }
            }

            Label(state.activeAppName, systemImage: "macwindow")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Chuyển Việt/Anh: ⌃⌥Space")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            if #available(macOS 14.0, *) {
                SettingsLink {
                    Text("Cài đặt…")
                }
            } else {
                Button("Cài đặt…") {
                    NSApp.sendAction(
                        Selector(("showPreferencesWindow:")),
                        to: nil,
                        from: nil
                    )
                }
            }
            Button("Thoát VType") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 270)
    }
}
