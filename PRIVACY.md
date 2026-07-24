# Privacy

VType xử lý sự kiện bàn phím cục bộ để chuyển Telex thành Unicode tiếng Việt.

## Dữ liệu được xử lý

- Phím đang gõ và một buffer ngắn của composition hiện tại.
- Khi buffer bị mất và người dùng nhấn phím dấu, tối đa 64 ký tự trước caret có
  thể được đọc qua Accessibility để khôi phục từ tiếng Việt ngay trước con trỏ.
- Tên/bundle identifier của ứng dụng hiện tại để áp dụng profile tương thích.

## Dữ liệu không được thu thập

- Không network hoặc telemetry.
- Không tài khoản, analytics hay quảng cáo.
- Không lưu lịch sử gõ xuống disk.
- Không đưa nội dung gõ vào macOS unified log.
- Không đọc context khi selection khác rỗng hoặc control được xác định là
  password/secure field.

Dữ liệu composition và debug trace chỉ tồn tại trong memory của process và bị
thay thế/reset trong quá trình sử dụng hoặc khi app thoát.

Nếu cả `VType` và `VType Dev` đang chạy, hai process chỉ trao đổi bundle
identifier qua macOS distributed notification để chọn một EventTap đang hoạt
động. Nội dung bàn phím và composition không được gửi giữa hai process.

## Quyền macOS

VType cần Accessibility để bắt và thay thế event bàn phím trên toàn hệ thống.
Bạn có thể thu hồi quyền bất kỳ lúc nào tại **System Settings → Privacy &
Security → Accessibility**, sau đó thoát VType.

Mọi thay đổi làm phát sinh network, telemetry hoặc lưu trữ nội dung phải được
công bố trong tài liệu này trước khi phát hành.
