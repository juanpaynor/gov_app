import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthService {
  // Get current user
  User? get currentUser => supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Check if user is guest
  bool get isGuest => !isLoggedIn;

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    // Create user profile in user_profiles table
    if (response.user != null) {
      try {
        await supabase.from('user_profiles').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'role': 'citizen',
        });
      } catch (e) {
        // If profile creation fails, log but don't block signup
        // The user can still use the app with metadata fallback
        print('Warning: Failed to create user profile: $e');
      }
    }

    return response;
  }

  // Sign out
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Continue as guest (just returns without auth)
  void continueAsGuest() {
    // No action needed, just navigate
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}
