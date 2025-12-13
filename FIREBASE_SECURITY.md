# Firebase Realtime Database Security Rules

## 📋 Tổng quan

File này mô tả cách hoạt động của Firebase Security Rules cho ứng dụng Smart Home.

## 🔐 Cấu trúc bảo mật

### 1. **owner_uid** (Chỉ Authenticated Users)

```json
devices/{deviceId}/owner_uid
```

**Quyền:**

- ✅ **Read:** Chỉ owner hoặc khi chưa có owner
- ✅ **Write:** Chỉ khi chưa tồn tại (người kết nối đầu tiên)
- ❌ **ESP:** Không thể đọc/ghi

**Logic trong code:**

```dart
// SettingsCubit.connectToCloud()
// 1. Kiểm tra xem đã có owner chưa
final ownerSnapshot = await _database.child('devices/$deviceId/owner_uid').get();

if (ownerSnapshot.exists) {
  // Đã có owner, không cho phép chiếm quyền
  emit(SettingsError('Thiết bị đã được kết nối bởi người khác'));
} else {
  // Chưa có owner, user này sẽ là owner
  await _database.child('devices/$deviceId/owner_uid').set(userUid);
}
```

### 2. **authorized_users** (Chỉ Authenticated Users)

```json
devices/{deviceId}/authorized_users/{userUid}
```

**Quyền:**

- ✅ **Read:** Owner hoặc authorized users
- ✅ **Write:** Chỉ owner (để thêm/xóa users)
- ❌ **ESP:** Không thể đọc/ghi

**Giá trị:**

- `true` = User có quyền điều khiển
- `false` hoặc không tồn tại = Không có quyền

### 3. **data** (Mọi người, bao gồm ESP)

```json
devices/{deviceId}/data
```

**Quyền:**

- ✅ **Read:** Mọi người (ESP + App)
- ✅ **Write:** Mọi người (ESP + App)

**Lý do:** ESP cần ghi dữ liệu sensors và đọc lệnh điều khiển mà không cần authentication phức tạp.

**Dữ liệu:**

```json
{
  "addCard": 0,
  "doorAngle": 0,
  "fanState": 0,
  "flameDetected": 0,
  "gasLevel": 123,
  "humidity": 58,
  "ledState": 0, // App ghi (điều khiển)
  "rainDetected": 1,
  "temperature": 25, // ESP ghi (cảm biến)
  "speed": 70 // App ghi (điều khiển quạt)
}
```

**ESP Firmware:** Đọc/ghi trực tiếp mà không cần auth
**App:** Phải authenticated, nhưng sau đó có thể đọc/ghi

### 4. **card** (RFID - Mọi người)

```json
devices/{deviceId}/card
```

**Quyền:**

- ✅ **Read:** Mọi người (ESP + App)
- ✅ **Write:** Mọi người (ESP + App)

**Lý do:** ESP cần ghi card RFID khi quét thẻ mới.

## 🚀 Deploy Firebase Rules

### Cách 1: Qua Firebase Console (Khuyến nghị)

1. Mở [Firebase Console](https://console.firebase.google.com/)
2. Chọn project **smart-944cb**
3. Vào **Realtime Database** → **Rules**
4. Copy nội dung từ `database.rules.json`
5. Paste vào và nhấn **Publish**

### Cách 2: Qua Firebase CLI

```bash
# Cài đặt Firebase CLI (nếu chưa có)
npm install -g firebase-tools

# Login
firebase login

# Deploy rules
firebase deploy --only database
```

## 🔄 Luồng kết nối thiết bị

### Kết nối lần đầu (Owner)

```
User 1 đăng nhập → Nhập mã "esp123" → connectToCloud()
  ↓
Kiểm tra devices/esp123/owner_uid
  ↓
Nếu CHƯA TỒN TẠI:
  → Ghi owner_uid = User1_UID  ✅
  → Ghi authorized_users/User1_UID = true  ✅
  → User 1 trở thành OWNER
```

### Kết nối sau (User khác)

```
User 2 đăng nhập → Nhập mã "esp123" → connectToCloud()
  ↓
Kiểm tra devices/esp123/owner_uid
  ↓
Nếu ĐÃ TỒN TẠI và khác User2_UID:
  → ❌ Lỗi: "Thiết bị đã được kết nối bởi người khác"
  → User 2 KHÔNG thể chiếm quyền
```

### Thêm user vào authorized_users (Owner only)

```
Owner → Vào settings → Thêm User 2
  ↓
Ghi devices/esp123/authorized_users/User2_UID = true
  ↓
User 2 giờ có thể điều khiển thiết bị ✅
```

## ⚠️ Lưu ý bảo mật

### ✅ Đã bảo vệ

1. **owner_uid:** Không thể bị ghi đè bởi user khác
2. **authorized_users:** Chỉ owner mới thêm/xóa được
3. **Logic trong code:** Kiểm tra owner trước khi ghi

### ⚠️ Cần lưu ý

1. **data và card:** Mọi người có thể đọc/ghi (để ESP hoạt động)

   - Nếu lo ngại bảo mật, cân nhắc:
     - Giới hạn theo IP
     - Sử dụng Firebase Functions làm proxy
     - Implement device authentication với token

2. **ESP không authenticated:**
   - ESP ghi dữ liệu mà không cần đăng nhập
   - Rủi ro: Người khác có thể gửi dữ liệu giả nếu biết deviceId
   - Giải pháp: Có thể thêm device_token để xác thực ESP

## 🔐 Nâng cao bảo mật ESP (Tùy chọn)

Nếu muốn bảo vệ tốt hơn mà không phức tạp firmware:

```json
// Thêm vào rules
"data": {
  ".read": true,
  ".write": "
    // Cho phép authenticated users
    (auth != null && (
      root.child('devices/' + $deviceId + '/owner_uid').val() === auth.uid ||
      root.child('devices/' + $deviceId + '/authorized_users/' + auth.uid).val() === true
    )) ||
    // Hoặc kiểm tra device_token cho ESP
    (root.child('devices/' + $deviceId + '/device_token').val() === newData.child('_token').val())
  "
}
```

ESP gửi kèm token mỗi lần ghi:

```cpp
// ESP code
firebase.set("devices/esp123/data", {
  "ledState": 1,
  "_token": "abc123xyz"  // Token xác thực ESP
});
```

## 📊 Test Rules

Bạn có thể test rules trong Firebase Console:

1. Vào **Realtime Database** → **Rules** → **Rules Playground**
2. Test các trường hợp:
   - Authenticated user đọc data ✅
   - Unauthenticated đọc data ✅
   - User thường ghi owner_uid ❌
   - User khác xóa authorized_users ❌

## 🎯 Kết luận

**Đã đảm bảo:**

- ✅ Người kết nối đầu tiên = Owner
- ✅ Owner không thể bị thay thế
- ✅ Chỉ owner mới thêm authorized_users
- ✅ Chỉ authorized_users (value = true) mới được điều khiển (thông qua logic trong app)
- ✅ ESP có thể đọc/ghi data và card tự do (cho đơn giản)

**Logic kiểm soát quyền:**

- Firebase Rules: Bảo vệ owner_uid và authorized_users
- App Logic: Kiểm tra quyền trước khi cho phép user kết nối
- ESP: Tự do đọc/ghi data để không phức tạp firmware
