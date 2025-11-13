import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

// Events
abstract class SpeechEvent {}

class InitSpeechEvent extends SpeechEvent {}

class StartListeningEvent extends SpeechEvent {}

class StopListeningEvent extends SpeechEvent {}

class SpeechResultEvent extends SpeechEvent {
  final String result;
  SpeechResultEvent(this.result);
}

// States
abstract class SpeechState {}

class SpeechInitial extends SpeechState {}

class SpeechInitializing extends SpeechState {}

class SpeechReady extends SpeechState {}

class SpeechListening extends SpeechState {
  final String currentWords;
  SpeechListening(this.currentWords);
}

class SpeechResult extends SpeechState {
  final String recognizedWords;
  SpeechResult(this.recognizedWords);
}

class SpeechError extends SpeechState {
  final String message;
  SpeechError(this.message);
}

class SpeechNotAvailable extends SpeechState {}

// Cubit
class SpeechCubit extends Cubit<SpeechState> {
  final SpeechToText _speechToText;
  bool _speechEnabled = false;

  SpeechCubit(this._speechToText) : super(SpeechInitial()) {
    initSpeech();
  }

  Future<void> initSpeech() async {
    try {
      emit(SpeechInitializing());
      _speechEnabled = await _speechToText.initialize();
      if (_speechEnabled) {
        emit(SpeechReady());
      } else {
        emit(SpeechNotAvailable());
      }
    } catch (e) {
      emit(SpeechError('Lỗi khởi tạo: $e'));
    }
  }

  Future<void> startListening() async {
    if (!_speechEnabled) {
      emit(SpeechError('Nhận dạng giọng nói không khả dụng'));
      return;
    }

    try {
      await _speechToText.listen(onResult: _onSpeechResult, localeId: 'vi_VN');
      emit(SpeechListening(''));
    } catch (e) {
      emit(SpeechError('Lỗi khi bắt đầu lắng nghe: $e'));
    }
  }

  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      emit(SpeechReady());
    } catch (e) {
      emit(SpeechError('Lỗi khi dừng lắng nghe: $e'));
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    emit(SpeechResult(result.recognizedWords));
  }

  bool get isListening => _speechToText.isListening;
}
