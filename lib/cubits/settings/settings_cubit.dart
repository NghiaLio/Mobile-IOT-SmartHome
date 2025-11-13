import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:developer';
import '../../services/connection_preferences_service.dart';

// States
abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class CloudConnectionSuccess extends SettingsState {
  final String message;
  CloudConnectionSuccess(this.message);
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError(this.message);
}

// Cubit
class SettingsCubit extends Cubit<SettingsState> {
  final DatabaseReference _database;

  SettingsCubit(this._database) : super(SettingsInitial());

  /// Kết nối thiết bị ESP với Cloud bằng cách lưu UID của người dùng vào Firebase
  Future<void> connectToCloud({
    required String userUid,
    required String deviceId,
  }) async {
    try {
      emit(SettingsLoading());

      // Lưu owner_uid vào devices/{deviceId}/owner_uid
      await _database.child('devices/$deviceId/owner_uid').set(userUid);
      log('Đã lưu owner_uid: devices/$deviceId/owner_uid = $userUid');

      // Thêm user vào authorized_users: devices/{deviceId}/authorized_users/{userUid} = true
      await _database
          .child('devices/$deviceId/authorized_users/$userUid')
          .set(true);
      log(
        'Đã thêm user vào authorized_users: devices/$deviceId/authorized_users/$userUid = true',
      );

      // Lưu connection status vào SharedPreferences
      await ConnectionPreferencesService.saveConnected(userUid, deviceId);
      log('Đã lưu connection status vào SharedPreferences');

      emit(CloudConnectionSuccess('Kết nối cloud thành công!'));
    } catch (e) {
      log('Lỗi kết nối cloud: $e');
      emit(SettingsError('Lỗi kết nối cloud: $e'));
    }
  }

  /// Kiểm tra xem thiết bị đã được kết nối chưa
  Future<bool> isDeviceConnected({required String deviceId}) async {
    try {
      final snapshot =
          await _database.child('devices/$deviceId/owner_uid').get();
      return snapshot.exists;
    } catch (e) {
      log('Lỗi kiểm tra kết nối: $e');
      return false;
    }
  }

  /// Reset state trở về initial
  void resetState() {
    emit(SettingsInitial());
  }
}
