# Ứng dụng Nhà Thông Minh (Smart Home)

Ứng dụng Flutter quản lý, điều khiển và giám sát thiết bị nhà thông minh qua Firebase Realtime Database.

## Tính năng chính

- Đăng ký, đăng nhập tài khoản bằng email/password
- Kết nối thiết bị IoT (ESP32, v.v.) với tài khoản người dùng
- Điều khiển thiết bị (bật/tắt đèn, quạt, điều hòa...) từ xa
- Nhận dạng giọng nói để điều khiển thiết bị bằng tiếng Việt/Anh
- Quản lý, chia sẻ quyền truy cập thiết bị qua mã chia sẻ/QR code
- Cảnh báo an toàn: phát hiện khí gas, lửa, mưa, nhiệt độ, độ ẩm
- Quản lý thẻ RFID ra vào
- Lưu trạng thái thiết bị, lịch sử truy cập
- Giao diện hiện đại, hỗ trợ chế độ sáng/tối

## Hướng dẫn cài đặt

1. Clone dự án về máy:
   ```bash
   git clone <repo-url>
   cd smart_home
   ```
2. Cài đặt dependencies:
   ```bash
   flutter pub get
   ```
3. Thêm file cấu hình Firebase:
   - Tải `google-services.json` (Android) vào `android/app/`
   - Tải `GoogleService-Info.plist` (iOS) vào `ios/Runner/`
4. Chạy ứng dụng:
   ```bash
   flutter run
   ```

## Cài đặt ứng dụng

Bạn có thể tải các file cài đặt APK, tài liệu hướng dẫn, hoặc các tài nguyên liên quan tại:
[Google Drive - Smart Home Installation](https://drive.google.com/drive/folders/1R-O35l5pwepJnr1QjEvjMMr2vpZLeL_n?usp=sharing)

## Cấu trúc thư mục

- `lib/screens/` - Giao diện các màn hình (đăng nhập, home, cài đặt, chia sẻ...)
- `lib/cubits/` - State management (BLoC/Cubit cho auth, device, settings...)
- `lib/services/` - Dịch vụ kết nối Firebase, preferences
- `lib/utils/` - Tiện ích nhận dạng giọng nói, xử lý lệnh
- `database.rules.json` - Quy tắc bảo mật Firebase

## Công nghệ sử dụng

- Flutter (Dart)
- Firebase Realtime Database, Auth
- speech_to_text (nhận dạng giọng nói)
- flutter_bloc (quản lý trạng thái)
- mobile_scanner (quét QR)

## Ghi chú bảo mật

- Chỉ chủ sở hữu mới có quyền chia sẻ thiết bị
- Người dùng khác chỉ truy cập khi được cấp quyền qua mã chia sẻ
- Dữ liệu thiết bị được bảo vệ qua Firebase Security Rules

## Đóng góp & phát triển

- Fork, tạo pull request hoặc liên hệ tác giả để đóng góp thêm tính năng!

---

© 2025 - Ứng dụng Nhà Thông Minh Flutter
