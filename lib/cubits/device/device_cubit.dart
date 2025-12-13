import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:developer';

import 'package:smart_home/services/connection_preferences_service.dart';

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
  final int humidity;
  final int gasLevel;
  final int flameDetected;
  final int rainDetected;
  final int doorAngle;

  DeviceLoaded({
    required this.lightState,
    required this.fanState,
    required this.acState,
    this.temperature = 0.0,
    this.speed = 0,
    this.humidity = 0,
    this.gasLevel = 0,
    this.flameDetected = 0,
    this.rainDetected = 1,
    this.doorAngle = 0,
  });

  DeviceLoaded copyWith({
    bool? lightState,
    bool? fanState,
    bool? acState,
    double? temperature,
    int? speed,
    int? humidity,
    int? gasLevel,
    int? flameDetected,
    int? rainDetected,
    int? doorAngle,
  }) {
    return DeviceLoaded(
      lightState: lightState ?? this.lightState,
      fanState: fanState ?? this.fanState,
      acState: acState ?? this.acState,
      temperature: temperature ?? this.temperature,
      speed: speed ?? this.speed,
      humidity: humidity ?? this.humidity,
      gasLevel: gasLevel ?? this.gasLevel,
      flameDetected: flameDetected ?? this.flameDetected,
      rainDetected: rainDetected ?? this.rainDetected,
      doorAngle: doorAngle ?? this.doorAngle,
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

  DeviceCubit(this._database) : super(DeviceInitial()) {
    loadDeviceState();
  }

  void loadDeviceState() async {
    // Đọc dữ liệu từ devices/{deviceId}/data
    final String deviceId =
        await ConnectionPreferencesService.getConnectedDeviceId() as String;
    _database
        .child('devices/$deviceId/data')
        .onValue
        .listen(
          (event) {
            final data = event.snapshot.value;
            log('Đọc dữ liệu từ devices/$deviceId/data: $data');

            if (data != null && data is Map) {
              final ledState = data['ledState'] ?? 0;
              final fanState = data['fanState'] ?? 0;
              final temperature = (data['temperature'] ?? 0).toDouble();
              final speed = (data['speed'] ?? 0).toInt();
              final humidity = (data['humidity'] ?? 0).toInt();
              final gasLevel = (data['gasLevel'] ?? 0).toInt();
              final flameDetected = (data['flameDetected'] ?? 0).toInt();
              final rainDetected = (data['rainDetected'] ?? 1).toInt();
              final doorAngle = (data['doorAngle'] ?? 0).toInt();

              final currentState = state;
              if (currentState is DeviceLoaded) {
                emit(
                  currentState.copyWith(
                    lightState: ledState == 1,
                    fanState: fanState == 1,
                    temperature: temperature,
                    speed: speed,
                    humidity: humidity,
                    gasLevel: gasLevel,
                    flameDetected: flameDetected,
                    rainDetected: rainDetected,
                    doorAngle: doorAngle,
                  ),
                );
              } else {
                emit(
                  DeviceLoaded(
                    lightState: ledState == 1,
                    fanState: fanState == 1,
                    acState: false,
                    temperature: temperature,
                    speed: speed,
                    humidity: humidity,
                    gasLevel: gasLevel,
                    flameDetected: flameDetected,
                    rainDetected: rainDetected,
                    doorAngle: doorAngle,
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
    final String deviceId =
        await ConnectionPreferencesService.getConnectedDeviceId() as String;
    try {
      await _database
          .child('devices/$deviceId/data/ledState')
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
    final String deviceId =
        await ConnectionPreferencesService.getConnectedDeviceId() as String;
    try {
      await _database
          .child('devices/$deviceId/data/fanState')
          .set(value ? 1 : 0);
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
      final String deviceId =
          await ConnectionPreferencesService.getConnectedDeviceId() as String;
      await _database
          .child('devices/$deviceId/data/temperature')
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
