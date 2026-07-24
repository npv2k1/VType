# Contributing to VType

Cảm ơn bạn muốn cải thiện VType. Dự án ưu tiên thay đổi nhỏ, có regression test
và không làm giảm quyền riêng tư của người dùng.

## Thiết lập

Yêu cầu macOS 13+, Xcode 15+ và XcodeGen:

```bash
make setup
make ci
```

`VType.xcodeproj` được sinh từ `project.yml`; không commit project đã sinh.

## Quy trình thay đổi

1. Tạo branch từ `main`.
2. Viết test thất bại cho bug/rule engine trước khi sửa nếu có thể.
3. Giữ `VType/Core` độc lập với AppKit/CoreGraphics.
4. Chạy `swift test` và `make test`.
5. Kiểm tra thủ công trong TextEdit và ít nhất một app bị ảnh hưởng đối với thay
   đổi event tap/injection.
6. Mở pull request và mô tả tác động đến quyền, dữ liệu hoặc nội dung bàn phím.

## Quy tắc riêng tư

- Không log, lưu hoặc gửi nội dung người dùng đã gõ.
- Không đọc secure/password field.
- Không thêm network, telemetry hoặc crash reporting nếu chưa có thảo luận công
  khai và opt-in rõ ràng.
- Debug trace phải nằm trong memory, có giới hạn và không đi vào unified system
  log.

## Coding và test

- Rule Telex phải tổng quát, không special-case một từ cụ thể.
- Core tests nằm trong `VTypeTests/Core`.
- Event synthetic phải có marker và event tap phải bỏ qua marker.
- Thay đổi Accessibility hoặc injection cần mô tả fallback và ứng dụng đã test.

Mọi đóng góp được gửi vào repository này sẽ được cấp phép theo giấy phép MIT
của dự án.
