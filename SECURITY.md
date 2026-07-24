# Security Policy

## Supported versions

Trong giai đoạn preview, chỉ bản mới nhất trên GitHub Releases được hỗ trợ.

## Reporting a vulnerability

Không tạo public issue cho lỗ hổng có thể làm lộ nội dung bàn phím, vượt qua
secure input, thực thi code, giả mạo artifact hoặc phá vỡ boundary quyền macOS.

Hãy dùng **GitHub Security Advisories → Report a vulnerability** trong
repository. Báo cáo nên có:

- phiên bản VType và macOS;
- tác động và điều kiện khai thác;
- bước tái hiện tối thiểu bằng dữ liệu không nhạy cảm;
- bản vá đề xuất nếu có.

Maintainer sẽ xác nhận trong vòng 7 ngày và cập nhật tiến độ ít nhất mỗi 14 ngày
cho tới khi có phương án xử lý. Không gửi password, private text, certificate,
Apple app-specific password hoặc signing secret.

## Release integrity

Artifact hiện tại dùng ad-hoc signature để cung cấp identity cho macOS
Accessibility, nhưng chữ ký này không xác minh tác giả và artifact không được
Apple notarize. Artifact chỉ được phát hành qua GitHub Releases, kèm tag, commit,
build metadata và file SHA-256. Người dùng cần kiểm tra checksum; không tin cậy
binary được chia sẻ qua kênh khác. Khi dự án có Developer ID, chính sách này phải
được cập nhật cùng release workflow trước khi gọi artifact là Developer ID
signed hoặc notarized.
