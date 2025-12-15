import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'dart:developer';

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
        log('Auth state changed: user logged in ${user.email}');
        emit(AuthAuthenticated(user));
      } else {
        log('Auth state changed: user logged out');
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
      final userCredential = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      log('Đăng ký thành công: $email');
      final user = userCredential?.user;
      if (user != null) {
        // Ensure latest user data
        await user.reload();
        final current = _authService.currentUser ?? user;
        log('Emitting AuthAuthenticated for ${current.email} (signup)');
        emit(AuthAuthenticated(current));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      emit(AuthLoading());
      final userCredential = await _authService.signIn(
        email: email,
        password: password,
      );
      log('Đăng nhập thành công: $email');
      final user = userCredential?.user;
      if (user != null) {
        // Reload to ensure auth State stabilizes and persistent state set
        await user.reload();
        final current = _authService.currentUser ?? user;
        log('Emitting AuthAuthenticated for ${current.email} (signin)');
        emit(AuthAuthenticated(current));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      emit(AuthLoading());
      await _authService.signOut();
      log('Đăng xuất thành công');
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
