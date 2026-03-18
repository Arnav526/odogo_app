import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/email_link_auth_service.dart'; // Adjust if needed
import '../repositories/user_repository.dart';
import '../models/user_model.dart';

// --- Auth States ---
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String email;
  AuthOtpSent(this.email);
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}

class AuthNeedsProfileSetup extends AuthState {
  final String email;
  AuthNeedsProfileSetup(this.email);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// --- Providers ---
final userRepositoryProvider = Provider((ref) => UserRepository());

// 1. UPDATED to NotifierProvider
final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

// A helper provider so other controllers/UI can easily grab the logged-in user
final currentUserProvider = Provider<UserModel?>((ref) {
  final state = ref.watch(authControllerProvider);
  if (state is AuthAuthenticated) {
    return state.user;
  }
  return null;
});

// --- Controller ---
// 2. UPDATED to Notifier
class AuthController extends Notifier<AuthState> {
  final EmailOtpAuthService _authService = EmailOtpAuthService.instance;

  // 3. Notifiers use a build() method to set the initial state
  @override
  AuthState build() {
    // Fire off the session check immediately after building
    Future.microtask(() => _checkSavedSession());
    return AuthInitial();
  }

  // 4. We can access 'ref' directly inside a Notifier to read the repo!
  UserRepository get _userRepo => ref.read(userRepositoryProvider);

  Future<void> _checkSavedSession() async {
    state = AuthLoading();
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('odogo_user_email');

    if (savedEmail != null) {
      final userModel = await _userRepo.getUserByEmail(savedEmail);
      if (userModel != null) {
        state = AuthAuthenticated(userModel);
      } else {
        state = AuthNeedsProfileSetup(savedEmail);
      }
    } else {
      state = AuthInitial();
    }
  }

  Future<void> sendOtp(String email) async {
    state = AuthLoading();
    try {
      await _authService.sendOtp(email: email);
      state = AuthOtpSent(email);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    state = AuthLoading();
    try {
      final isValid = _authService.verifyOtp(email: email, otp: otp);

      if (!isValid) {
        state = AuthError("Invalid or expired OTP. Please try again.");
        return;
      }

      // Save to local storage so they don't have to login next time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('odogo_user_email', email);

      final userModel = await _userRepo.getUserByEmail(email);

      if (userModel != null) {
        state = AuthAuthenticated(userModel);
      } else {
        state = AuthNeedsProfileSetup(email);
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('odogo_user_email');
    state = AuthInitial();
  }
}
