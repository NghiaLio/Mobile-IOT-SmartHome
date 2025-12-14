import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:developer';
import 'dart:math' as math;
import '../../services/connection_preferences_service.dart';

// Model for Share Code
class ShareCode {
  final String id;
  final String code;
  final String deviceId;
  final String createdBy;
  final int createdAt;
  final int expiresAt;
  final int maxUses;
  final int usedCount;
  final bool isActive;

  ShareCode({
    required this.id,
    required this.code,
    required this.deviceId,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    required this.maxUses,
    required this.usedCount,
    required this.isActive,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;
  bool get canUse => isActive && !isExpired && usedCount < maxUses;

  factory ShareCode.fromMap(String id, Map<dynamic, dynamic> map) {
    return ShareCode(
      id: id,
      code: map['code'] ?? '',
      deviceId: map['device_id'] ?? '',
      createdBy: map['created_by'] ?? '',
      createdAt: map['created_at'] ?? 0,
      expiresAt: map['expires_at'] ?? 0,
      maxUses: map['max_uses'] ?? 1,
      usedCount: map['used_count'] ?? 0,
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'device_id': deviceId,
      'created_by': createdBy,
      'created_at': createdAt,
      'expires_at': expiresAt,
      'max_uses': maxUses,
      'used_count': usedCount,
      'is_active': isActive,
    };
  }
}

// States
abstract class ShareState {}

class ShareInitial extends ShareState {}

class ShareLoading extends ShareState {}

class ShareCodeGenerated extends ShareState {
  final ShareCode shareCode;
  ShareCodeGenerated(this.shareCode);
}

class ShareCodeValidated extends ShareState {
  final ShareCode shareCode;
  final String deviceId;
  ShareCodeValidated({required this.shareCode, required this.deviceId});
}

class ShareSuccess extends ShareState {
  final String message;
  ShareSuccess(this.message);
}

class ShareError extends ShareState {
  final String message;
  ShareError(this.message);
}

// Cubit
class ShareCubit extends Cubit<ShareState> {
  final DatabaseReference _database;

  ShareCubit(this._database) : super(ShareInitial());

  // Generate random 6-character code
  String _generateCode() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Bỏ 0,O,1,I để tránh nhầm
    final random = math.Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Tạo mã share mới
  Future<void> generateShareCode({
    required String userUid,
    int validHours = 24,
    int maxUses = 1,
  }) async {
    try {
      emit(ShareLoading());

      final deviceId =
          await ConnectionPreferencesService.getConnectedDeviceId();
      if (deviceId == null) {
        emit(ShareError('Không tìm thấy thiết bị đã kết nối'));
        return;
      }

      // Kiểm tra user có phải owner không
      final ownerSnapshot =
          await _database.child('devices/$deviceId/owner_uid').get();
      if (!ownerSnapshot.exists || ownerSnapshot.value != userUid) {
        emit(ShareError('Chỉ chủ sở hữu mới có thể share thiết bị'));
        return;
      }

      // Tạo mã code unique
      String code;
      bool isUnique = false;
      int attempts = 0;

      do {
        code = _generateCode();
        // Kiểm tra code đã tồn tại chưa
        final snapshot =
            await _database
                .child('devices/$deviceId/share_codes')
                .orderByChild('code')
                .equalTo(code)
                .get();

        isUnique = !snapshot.exists;
        attempts++;

        if (attempts > 10) {
          emit(ShareError('Không thể tạo mã unique, vui lòng thử lại'));
          return;
        }
      } while (!isUnique);

      // Tạo share code object
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = now + (validHours * 60 * 60 * 1000);

      final shareCode = ShareCode(
        id: '', // Sẽ được set bởi Firebase push
        code: code,
        deviceId: deviceId,
        createdBy: userUid,
        createdAt: now,
        expiresAt: expiresAt,
        maxUses: maxUses,
        usedCount: 0,
        isActive: true,
      );

      // Lưu vào Firebase
      final ref = _database.child('devices/$deviceId/share_codes').push();

      await ref.set(shareCode.toMap());

      log('Đã tạo share code: $code');

      emit(
        ShareCodeGenerated(
          ShareCode(
            id: ref.key!,
            code: shareCode.code,
            deviceId: shareCode.deviceId,
            createdBy: shareCode.createdBy,
            createdAt: shareCode.createdAt,
            expiresAt: shareCode.expiresAt,
            maxUses: shareCode.maxUses,
            usedCount: shareCode.usedCount,
            isActive: shareCode.isActive,
          ),
        ),
      );
    } catch (e) {
      log('Lỗi khi tạo share code: $e');
      emit(ShareError('Lỗi khi tạo mã share: $e'));
    }
  }

  // Validate và sử dụng mã share
  Future<void> validateAndUseShareCode({
    required String code,
    required String userUid,
  }) async {
    try {
      emit(ShareLoading());

      // Tìm kiếm code trong tất cả devices
      final devicesSnapshot = await _database.child('devices').get();

      if (!devicesSnapshot.exists) {
        emit(ShareError('Mã không hợp lệ'));
        return;
      }

      ShareCode? foundCode;
      String? deviceId;

      // Tìm code trong các devices
      final devicesData = devicesSnapshot.value as Map<dynamic, dynamic>;

      for (var entry in devicesData.entries) {
        final device = entry.value as Map<dynamic, dynamic>;
        final shareCodes = device['share_codes'];

        if (shareCodes != null && shareCodes is Map) {
          for (var codeEntry in shareCodes.entries) {
            final shareCodeData = codeEntry.value as Map<dynamic, dynamic>;
            if (shareCodeData['code'] == code) {
              foundCode = ShareCode.fromMap(codeEntry.key, shareCodeData);
              deviceId = entry.key;
              break;
            }
          }
        }

        if (foundCode != null) break;
      }

      if (foundCode == null || deviceId == null) {
        emit(ShareError('Mã không hợp lệ'));
        return;
      }

      // Kiểm tra mã còn sử dụng được không
      if (!foundCode.canUse) {
        if (foundCode.isExpired) {
          emit(ShareError('Mã đã hết hạn'));
        } else if (foundCode.usedCount >= foundCode.maxUses) {
          emit(ShareError('Mã đã được sử dụng hết'));
        } else {
          emit(ShareError('Mã không còn hoạt động'));
        }
        return;
      }

      // Kiểm tra user đã được authorize chưa
      final authSnapshot =
          await _database
              .child('devices/$deviceId/authorized_users/$userUid')
              .get();

      if (authSnapshot.exists && authSnapshot.value == true) {
        emit(ShareError('Bạn đã có quyền truy cập thiết bị này'));
        return;
      }

      // Thêm user vào authorized_users
      await _database
          .child('devices/$deviceId/authorized_users/$userUid')
          .set(true);

      // Cập nhật used_count
      await _database
          .child('devices/$deviceId/share_codes/${foundCode.id}/used_count')
          .set(foundCode.usedCount + 1);

      // Nếu đã dùng hết, deactivate
      if (foundCode.usedCount + 1 >= foundCode.maxUses) {
        await _database
            .child('devices/$deviceId/share_codes/${foundCode.id}/is_active')
            .set(false);
      }

      // Lưu kết nối vào SharedPreferences
      await ConnectionPreferencesService.saveConnected(userUid, deviceId);

      log('Đã thêm user $userUid vào device $deviceId');

      emit(ShareSuccess('Đã kết nối thành công đến thiết bị!'));
    } catch (e) {
      log('Lỗi khi validate share code: $e');
      emit(ShareError('Lỗi khi xử lý mã: $e'));
    }
  }

  // Reset state
  void resetState() {
    emit(ShareInitial());
  }
}
