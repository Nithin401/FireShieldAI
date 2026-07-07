import 'dart:async';
import 'package:fireshield_app/domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final StreamController<String?> _authStateController = StreamController<String?>.broadcast();
  
  MockAuthRepository() {
    // Start unauthenticated
    _authStateController.add(null);
  }

  @override
  Stream<String?> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // simulate network delay
    // In mock mode, we accept any login and assign a fake user ID
    _authStateController.add('mock_user_123');
  }

  @override
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _authStateController.add('mock_user_123');
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _authStateController.add(null);
  }
}
