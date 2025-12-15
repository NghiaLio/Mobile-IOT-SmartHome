import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:smart_home/cubits/device/device_cubit.dart';
import 'dart:developer';

class SpeechUtils {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final DeviceCubit deviceCubit;
  bool _isListening = false;
  String _lastCommand = '';

  bool get isListening => _isListening;

  SpeechUtils(this.deviceCubit);

  Future<void> initialize() async {
    await _speech.initialize();
  }

  void startListening() {
    if (!_isListening) {
      _lastCommand = '';
      _speech.listen(
        localeId: 'vi_VN',
        listenFor: Duration(minutes: 5),
        pauseFor: Duration(minutes: 5),
        onResult: (result) {
          _lastCommand = result.recognizedWords.toLowerCase();
          log('Đang nghe: $_lastCommand');
          if (result.finalResult) {
            log('Kết quả cuối: $_lastCommand');
            _isListening = false;
            _processCommand(_lastCommand);
          }
        },
      );
      _isListening = true;
      log('Bắt đầu nghe...');
    }
  }

  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
      log('Dừng nghe. Xử lý lệnh: $_lastCommand');
      if (_lastCommand.isNotEmpty) {
        _processCommand(_lastCommand);
      }
    }
  }

  void toggleListening() {
    if (_isListening) {
      stopListening();
    } else {
      startListening();
    }
  }

  void _processCommand(String text) {
    String command = text.toLowerCase();
    log('Recognized command: $command');

    if (command.contains('turn on light') || command.contains('bật đèn')) {
      log('Toggling light on');
      deviceCubit.toggleLight(true);
    } else if (command.contains('turn off light') ||
        command.contains('tắt đèn')) {
      log('Toggling light off');
      deviceCubit.toggleLight(false);
    } else if (command.contains('turn on fan') ||
        command.contains('bật quạt')) {
      log('Toggling fan on');
      deviceCubit.toggleFan(true);
    } else if (command.contains('turn off fan') ||
        command.contains('tắt quạt')) {
      log('Toggling fan off');
      deviceCubit.toggleFan(false);
    } else if (command.contains('turn on ac') ||
        command.contains('bật điều hòa')) {
      log('Toggling AC on');
      deviceCubit.toggleAC(true);
    } else if (command.contains('turn off ac') ||
        command.contains('tắt điều hòa')) {
      log('Toggling AC off');
      deviceCubit.toggleAC(false);
    }
    // Thêm các lệnh khác nếu cần
  }
}
