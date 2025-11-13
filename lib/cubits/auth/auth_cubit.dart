import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import '../../services/connection_preferences_service.dart';

// Events
abstract class AuthEvent {}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  SignUpEvent({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  SignInEvent({required this.email, required this.password});
}

class SignOutEvent extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final User? user;
  AuthStateChanged(this.user);
}

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService) : super(AuthInitial()) {
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      emit(AuthLoading());
      await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      emit(AuthLoading());
      await _authService.signIn(email: email, password: password);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      emit(AuthLoading());
      await ConnectionPreferencesService.clearConnection();
      await _authService.signOut();
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
