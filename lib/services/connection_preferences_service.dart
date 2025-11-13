import 'package:shared_preferences/shared_preferences.dart';

class ConnectionPreferencesService {
  static const String _connectedKey = 'device_connected';
  static const String _userUidKey = 'connected_user_uid';
  static const String _deviceIdKey = 'connected_device_id';

  /// Lưu trạng thái kết nối đã thành công
  static Future<void> saveConnected(String userUid, String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_connectedKey, true);
    await prefs.setString(_userUidKey, userUid);
    await prefs.setString(_deviceIdKey, deviceId);
  }

  /// Kiểm tra thiết bị đã kết nối chưa
  static Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_connectedKey) ?? false;
  }

  /// Lấy UID của user đã kết nối
  static Future<String?> getConnectedUserUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userUidKey);
  }

  /// Lấy device ID
  static Future<String?> getConnectedDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceIdKey);
  }

  /// Xóa trạng thái kết nối (dùng khi logout)
  static Future<void> clearConnection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_connectedKey);
    await prefs.remove(_userUidKey);
    await prefs.remove(_deviceIdKey);
  }
}
