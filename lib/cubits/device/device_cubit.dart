import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:developer';

// Events
abstract class DeviceEvent {}

class LoadDeviceStateEvent extends DeviceEvent {}

class ToggleLightEvent extends DeviceEvent {
  final bool value;
  ToggleLightEvent(this.value);
}

class ToggleFanEvent extends DeviceEvent {
  final bool value;
  ToggleFanEvent(this.value);
}

class ToggleACEvent extends DeviceEvent {
  final bool value;
  ToggleACEvent(this.value);
}

// States
abstract class DeviceState {}

class DeviceInitial extends DeviceState {}

class DeviceLoading extends DeviceState {}

class DeviceLoaded extends DeviceState {
  final bool lightState;
  final bool fanState;
  final bool acState;
  final double temperature;
  final int speed;

  DeviceLoaded({
    required this.lightState,
    required this.fanState,
    required this.acState,
    this.temperature = 0.0,
    this.speed = 0,
  });

  DeviceLoaded copyWith({
    bool? lightState,
    bool? fanState,
    bool? acState,
    double? temperature,
    int? speed,
  }) {
    return DeviceLoaded(
      lightState: lightState ?? this.lightState,
      fanState: fanState ?? this.fanState,
      acState: acState ?? this.acState,
      temperature: temperature ?? this.temperature,
      speed: speed ?? this.speed,
    );
  }
}

class DeviceError extends DeviceState {
  final String message;
  DeviceError(this.message);
}

// Cubit
class DeviceCubit extends Cubit<DeviceState> {
  final DatabaseReference _database;
  final String _deviceId;

  DeviceCubit(this._database, {String deviceId = 'esp123'})
    : _deviceId = deviceId,
      super(DeviceInitial()) {
    loadDeviceState();
  }

  void loadDeviceState() {
    // Đọc dữ liệu từ devices/{deviceId}/data
    _database
        .child('devices/$_deviceId/data')
        .onValue
        .listen(
          (event) {
            final data = event.snapshot.value;
            log('Đọc dữ liệu từ devices/$_deviceId/data: $data');

            if (data != null && data is Map) {
              final ledState = data['ledState'] ?? 0;
              final temperature = (data['temperature'] ?? 0).toDouble();
              final speed = data['speed'] ?? 0;

              final currentState = state;
              if (currentState is DeviceLoaded) {
                emit(
                  currentState.copyWith(
                    lightState: ledState == 1,
                    temperature: temperature,
                    speed: speed,
                  ),
                );
              } else {
                emit(
                  DeviceLoaded(
                    lightState: ledState == 1,
                    fanState: false,
                    acState: false,
                    temperature: temperature,
                    speed: speed,
                  ),
                );
              }
            }
          },
          onError: (error) {
            log('Lỗi đọc dữ liệu thiết bị: $error');
            emit(DeviceError('Lỗi đọc dữ liệu: $error'));
          },
        );
  }

  Future<void> toggleLight(bool value) async {
    try {
      await _database
          .child('devices/$_deviceId/data/ledState')
          .set(value ? 1 : 0);
      log('Cập nhật LED: ${value ? "bật" : "tắt"}');

      final currentState = state;
      if (currentState is DeviceLoaded) {
        emit(currentState.copyWith(lightState: value));
      }
    } catch (e) {
      log('Lỗi cập nhật LED: $e');
      emit(DeviceError('Lỗi cập nhật đèn: $e'));
    }
  }

  Future<void> toggleFan(bool value) async {
    try {
      await _database
          .child('devices/$_deviceId/data/speed')
          .set(value ? 70 : 0);
      log('Cập nhật quạt: ${value ? "bật" : "tắt"}');

      final currentState = state;
      if (currentState is DeviceLoaded) {
        emit(currentState.copyWith(fanState: value));
      }
    } catch (e) {
      log('Lỗi cập nhật quạt: $e');
      emit(DeviceError('Lỗi cập nhật quạt: $e'));
    }
  }

  Future<void> toggleAC(bool value) async {
    try {
      // Có thể điều chỉnh temperature để điều khiển AC
      await _database
          .child('devices/$_deviceId/data/temperature')
          .set(value ? 20 : 0);
      log('Cập nhật điều hòa: ${value ? "bật" : "tắt"}');

      final currentState = state;
      if (currentState is DeviceLoaded) {
        emit(currentState.copyWith(acState: value));
      }
    } catch (e) {
      log('Lỗi cập nhật điều hòa: $e');
      emit(DeviceError('Lỗi cập nhật điều hòa: $e'));
    }
  }
}
