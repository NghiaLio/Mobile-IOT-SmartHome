import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy current user
  User? get currentUser => _auth.currentUser;

  // Stream để theo dõi trạng thái xác thực
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng ký
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Cập nhật display name
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Đăng nhập
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Xử lý lỗi Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy người dùng với email này.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'operation-not-allowed':
        return 'Phép đăng ký bị vô hiệu hóa.';
      default:
        return 'Lỗi: ${e.message}';
    }
  }
}
