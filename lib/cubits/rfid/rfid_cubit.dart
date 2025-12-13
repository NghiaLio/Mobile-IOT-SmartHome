import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:developer';
import '../../services/connection_preferences_service.dart';

// Model for RFID Card
class RfidCard {
  final String id;
  final String cardNumber;

  RfidCard({
    required this.id,
    required this.cardNumber,
  });

  factory RfidCard.fromMap(String id, Map<dynamic, dynamic> map) {
    return RfidCard(
      id: id,
      cardNumber: map['card'] ?? '',
    );
  }
}

// States
abstract class RfidState {}

class RfidInitial extends RfidState {}

class RfidLoading extends RfidState {}

class RfidLoaded extends RfidState {
  final List<RfidCard> cards;
  final bool isAddingCard;

  RfidLoaded({
    required this.cards,
    this.isAddingCard = false,
  });

  RfidLoaded copyWith({
    List<RfidCard>? cards,
    bool? isAddingCard,
  }) {
    return RfidLoaded(
      cards: cards ?? this.cards,
      isAddingCard: isAddingCard ?? this.isAddingCard,
    );
  }
}

class RfidCardAdded extends RfidState {
  final RfidCard newCard;
  final List<RfidCard> allCards;

  RfidCardAdded({
    required this.newCard,
    required this.allCards,
  });
}

class RfidError extends RfidState {
  final String message;
  RfidError(this.message);
}

// Cubit
class RfidCubit extends Cubit<RfidState> {
  final DatabaseReference _database;
  int _previousCardCount = 0;

  RfidCubit(this._database) : super(RfidInitial()) {
    loadCards();
  }

  void loadCards() async {
    try {
      final String deviceId =
          await ConnectionPreferencesService.getConnectedDeviceId() as String;

      _database.child('devices/$deviceId/card').onValue.listen(
        (event) {
          final data = event.snapshot.value;
          log('Đọc dữ liệu cards: $data');

          if (data == null) {
            emit(RfidLoaded(cards: []));
            return;
          }

          if (data is Map) {
            List<RfidCard> cards = [];
            data.forEach((key, value) {
              if (value is Map) {
                cards.add(RfidCard.fromMap(key, value));
              }
            });

            // Sort by id (newest first)
            cards.sort((a, b) => b.id.compareTo(a.id));

            final currentState = state;
            
            // Check if a new card was added
            if (currentState is RfidLoaded && 
                cards.length > _previousCardCount && 
                _previousCardCount > 0 &&
                currentState.isAddingCard) {
              // New card detected
              final newCard = cards.first;
              log('Thẻ mới được thêm: ${newCard.cardNumber}');
              emit(RfidCardAdded(newCard: newCard, allCards: cards));
              
              // Reset addCard flag to 0
              _resetAddCardFlag();
            } else {
              emit(RfidLoaded(
                cards: cards,
                isAddingCard: currentState is RfidLoaded
                    ? currentState.isAddingCard
                    : false,
              ));
            }

            _previousCardCount = cards.length;
          }
        },
        onError: (error) {
          log('Lỗi đọc dữ liệu cards: $error');
          emit(RfidError('Lỗi đọc dữ liệu thẻ: $error'));
        },
      );
    } catch (e) {
      log('Lỗi load cards: $e');
      emit(RfidError('Lỗi tải danh sách thẻ: $e'));
    }
  }

  Future<void> startAddingCard() async {
    try {
      final currentState = state;
      if (currentState is RfidLoaded) {
        emit(currentState.copyWith(isAddingCard: true));
      }

      final String deviceId =
          await ConnectionPreferencesService.getConnectedDeviceId() as String;
      
      // Set addCard = 1 to trigger firmware
      await _database.child('devices/$deviceId/data/addCard').set(1);
      log('Đã bật chế độ thêm thẻ (addCard = 1)');
    } catch (e) {
      log('Lỗi khi bắt đầu thêm thẻ: $e');
      emit(RfidError('Lỗi khi bắt đầu thêm thẻ: $e'));
    }
  }

  Future<void> cancelAddingCard() async {
    try {
      final currentState = state;
      if (currentState is RfidLoaded) {
        emit(currentState.copyWith(isAddingCard: false));
      }

      final String deviceId =
          await ConnectionPreferencesService.getConnectedDeviceId() as String;
      
      // Reset addCard = 0 to cancel
      await _database.child('devices/$deviceId/data/addCard').set(0);
      log('Đã hủy chế độ thêm thẻ (addCard = 0)');
    } catch (e) {
      log('Lỗi khi hủy thêm thẻ: $e');
      emit(RfidError('Lỗi khi hủy thêm thẻ: $e'));
    }
  }

  Future<void> _resetAddCardFlag() async {
    try {
      final String deviceId =
          await ConnectionPreferencesService.getConnectedDeviceId() as String;
      
      // Reset addCard = 0
      await _database.child('devices/$deviceId/data/addCard').set(0);
      log('Đã tắt chế độ thêm thẻ (addCard = 0)');
    } catch (e) {
      log('Lỗi khi reset addCard: $e');
    }
  }

  Future<void> resetAllCards() async {
    try {
      emit(RfidLoading());
      
      final String deviceId =
          await ConnectionPreferencesService.getConnectedDeviceId() as String;
      
      // Xóa toàn bộ node card
      await _database.child('devices/$deviceId/card').remove();
      log('Đã xóa tất cả thẻ');
      
      emit(RfidLoaded(cards: [], isAddingCard: false));
    } catch (e) {
      log('Lỗi khi reset tất cả thẻ: $e');
      emit(RfidError('Lỗi khi reset thẻ: $e'));
    }
  }

  void resetToLoaded() {
    final currentState = state;
    if (currentState is RfidCardAdded) {
      emit(RfidLoaded(
        cards: currentState.allCards,
        isAddingCard: false,
      ));
    }
  }
}

