# VType

VType là bộ gõ tiếng Việt native cho macOS, tập trung vào developer thường xuyên
gõ lẫn tiếng Việt, tiếng Anh và code. MVP dùng `CGEventTap` để chèn Unicode trực
tiếp nên không tạo marked text/gạch chân như Input Method mặc định.

## MVP hiện có

- Telex: `aa/aw/dd/ee/oo/ow/uw`, dấu `s/f/r/x/j`, phím `z` để bỏ dấu.
- Unicode dựng sẵn, không dùng clipboard.
- Developer Mode: nhận diện và khôi phục từ tiếng Anh/code phổ biến.
- Tự passthrough shortcut Command/Control/Option và reset buffer khi di chuyển.
- Tự tắt xử lý trong Terminal khi chọn profile an toàn.
- Menu-bar SwiftUI, bật/tắt nhanh Việt/Anh.
- Hotkey toàn cục `⌃⌥Space`.
- Không network, không telemetry, không lưu nội dung đã gõ.
- Unit test cho engine và classifier.

## Yêu cầu

- macOS 13 trở lên.
- Xcode 15 trở lên.
- Homebrew chỉ cần để cài XcodeGen.

## Chạy project

```bash
make setup
make open
```

Trong Xcode:

1. Chọn scheme `VType`.
2. Build & Run.
3. Từ menu-bar, bấm **Cấp quyền Accessibility**.
4. Bật VType trong `System Settings → Privacy & Security → Accessibility`.
5. Tắt và mở lại VType nếu macOS chưa kích hoạt quyền ngay.

## Kiểm tra khi đã cấp quyền nhưng không gõ được

Mở **VType → Cài đặt → Chung** rồi nhìn hai dòng:

- `EventTap`: phải là **Đang chạy**.
- `Sự kiện bàn phím đã nhận`: phải tăng khi gõ trong một ô văn bản thường.

Nếu EventTap chưa chạy, bấm **Khởi động lại EventTap**. Nếu macOS vẫn từ
chối, vào `System Settings → Privacy & Security → Accessibility`, xóa bản
VType cũ khỏi danh sách, chạy lại đúng bản app vừa build rồi cấp quyền lại.
Quyền Accessibility của macOS gắn với identity/chữ ký của app; build Debug
thay đổi có thể khiến một mục VType cũ trông như đang bật nhưng không áp dụng
cho process hiện tại.

VType ghi log kỹ thuật nhưng không ghi nội dung bàn phím. Có thể xem bằng:

```bash
log stream --level debug --predicate \
  'subsystem == "dev.vtype.app" AND category == "EventTap"'
```

Nếu bộ đếm tăng nhưng chữ không được biến đổi, thử trước trong TextEdit hoặc
Notes, không thử trong password field vì Secure Input có thể chặn EventTap.

Có thể build/test bằng terminal:

```bash
make test
make build
```

Engine cũng là một Swift Package độc lập:

```bash
swift test
```

## Cấu trúc

```text
VType/
├── Core/
│   ├── DeveloperContextClassifier.swift
│   ├── TelexComposer.swift
│   └── VietnameseEngine.swift
├── Platform/
│   ├── AccessibilityPermission.swift
│   ├── EventTapManager.swift
│   ├── RuntimeState.swift
│   └── TextInjector.swift
├── UI/
│   ├── MenuBarView.swift
│   └── SettingsView.swift
├── Resources/
└── VTypeApp.swift
```

`Core` không import AppKit/CoreGraphics, vì vậy có thể test riêng và tái sử dụng
cho InputMethodKit trong giai đoạn sau. `Platform` chỉ làm nhiệm vụ bắt/gửi phím.

## Nguyên tắc xử lý

VType giữ hai buffer cho từ đang gõ:

- `raw`: phím thực người dùng gõ, ví dụ `tieengs`.
- `rendered`: kết quả đang hiển thị, ví dụ `tiếng`.

Khi Developer Mode phát hiện `process`, `async`, `UserService`, URL/path hoặc
identifier, engine thay phần đã biến đổi bằng đúng buffer `raw`. Nếu không đủ
chắc chắn, VType ưu tiên không phá code.

## Giới hạn MVP

- Mới hỗ trợ Telex; VNI chưa có.
- Danh sách từ developer/English còn nhỏ và nằm local.
- Chưa có InputMethodKit fallback, AX range replacement, macro và per-app editor.
- EventTap cần Accessibility; Secure Input có thể làm macOS tạm ngừng event tap.
- Compatibility cần được test thêm trên Google Docs, Notion, VS Code/Cursor,
  Terminal/iTerm/Warp và các editor canvas.

## Nguồn tham khảo

VType được viết mới, không sao chép engine. Thiết kế tham khảo:

- XKey: kiến trúc dual CGEvent/InputMethodKit và strategy theo ứng dụng.
- Caffee: app native Swift tối giản và nhớ mode theo ứng dụng.
- UniKey/OpenKey: quy tắc Telex và kinh nghiệm tương thích.

Chi tiết giấy phép và phạm vi tham khảo nằm trong
[`docs/OPEN_SOURCE_NOTICES.md`](docs/OPEN_SOURCE_NOTICES.md).
