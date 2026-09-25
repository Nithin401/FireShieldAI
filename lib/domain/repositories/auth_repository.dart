abstract class AuthRepository {
  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> signUpWithEmailAndPassword(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function() onAutoVerified,
  });
  Future<void> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
  });
  Future<void> signOut();
  Stream<String?> get authStateChanges;
  String? get currentUserId;
  String? get currentUserEmail;
  String? get currentUserPhone;
}
