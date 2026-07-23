import SwiftUI

struct SettingsView: View {
    @ObservedObject private var state = RuntimeState.shared

    var body: some View {
        TabView {
            Form {
                Section("Trạng thái") {
                    LabeledContent("EventTap") {
                        Text(state.isRunning ? "Đang chạy" : "Đã dừng")
                            .foregroundStyle(state.isRunning ? .green : .orange)
                    }
                    LabeledContent("Accessibility") {
                        Text(state.permissionGranted ? "Đã cấp" : "Chưa cấp")
                    }
                    LabeledContent("Sự kiện bàn phím đã nhận") {
                        Text("\(state.receivedEventCount)")
                            .monospacedDigit()
                    }

                    if !state.permissionGranted {
                        Button("Mở cài đặt Accessibility") {
                            AccessibilityPermission.request()
                            AccessibilityPermission.openSystemSettings()
                        }
                    } else {
                        Button("Khởi động lại EventTap") {
                            EventTapManager.shared.restart()
                        }
                    }

                    Text(state.diagnosticMessage)
                        .font(.caption)
                        .foregroundStyle(state.isRunning ? .secondary : .orange)
                }

                Section("Cách gõ") {
                    Toggle("Developer Mode", isOn: $state.developerMode)
                    Text("Giữ nguyên từ tiếng Anh, tên API, identifier và code phổ biến.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle("Tắt VType trong Terminal", isOn: $state.disableInTerminals)
                    Text("Hữu ích nếu Terminal chủ yếu dùng để nhập command.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Phím tắt") {
                    LabeledContent("Chuyển Việt/Anh", value: "⌃⌥Space")
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Chung", systemImage: "switch.2")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("VType 0.1.1")
                    .font(.title2.bold())
                Text("Bộ gõ Telex native cho macOS, tối ưu cho developer.")
                Text("Toàn bộ xử lý chạy local. VType không dùng mạng, không telemetry và không lưu nội dung đã gõ.")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(24)
            .tabItem {
                Label("Giới thiệu", systemImage: "info.circle")
            }
        }
        .frame(width: 520, height: 380)
    }
}
