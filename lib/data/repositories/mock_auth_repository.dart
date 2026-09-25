import 'dart:async';
import 'package:fireshield_app/domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final StreamController<String?> _authStateController = StreamController<String?>.broadcast();
  String? _currentUser;
  String? _currentEmail;
  String? _currentPhone;

  MockAuthRepository() {
    // Start unauthenticated
    _authStateController.add(null);
  }

  @override
  Stream<String?> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = 'mock_user_123';
    _currentEmail = email;
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = 'mock_user_123';
    _currentEmail = email;
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = 'mock_google_user';
    _currentEmail = 'demo.user@fireshield.ai';
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function() onAutoVerified,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentPhone = phoneNumber;
    onCodeSent('mock_verification_id_123456');
  }

  @override
  Future<void> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = 'mock_phone_user';
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _currentEmail = null;
    _currentPhone = null;
    _authStateController.add(null);
  }

  @override
  String? get currentUserId => _currentUser;

  @override
  String? get currentUserEmail => _currentEmail;

  @override
  String? get currentUserPhone => _currentPhone;
}
