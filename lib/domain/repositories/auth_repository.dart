abstract class AuthRepository {
  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> signUpWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Stream<String?> get authStateChanges; // Emits user ID if logged in, null otherwise
}
