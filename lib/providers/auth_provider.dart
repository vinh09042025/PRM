import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  User? _firebaseUser;
  bool _isLoading = true;

  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isLoading => _isLoading;
  String? get uid => _firebaseUser?.uid;

  AuthProvider() {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _firebaseUser = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<String?> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _getErrorMessage(e.code);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "Đã xảy ra lỗi không xác định.";
    }
  }

  Future<String?> register(String email, String password, String displayName) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name (username)
      await credential.user?.updateDisplayName(displayName);
      
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _getErrorMessage(e.code);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "Đã xảy ra lỗi khi đăng ký.";
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Không tìm thấy người dùng với email này.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      default:
        return 'Lỗi xác thực: $code';
    }
  }
}
