import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/core/services/auth_service.dart';

// Provider for the AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider for the current Firebase user
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Stream provider for auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

// Provider for user profile data
final userProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getUserProfile(userId);
});

// State notifier for login state
class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  final AuthService _authService;

  LoginNotifier(this._authService) : super(LoginState());

  Future<Map<String, dynamic>> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authService.login(email, password);

    if (result['success']) {
      state = state.copyWith(isLoading: false, isSuccess: true);
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result['message'],
        isSuccess: false,
      );
    }

    return result;
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authService.signInWithGoogle();

    if (result['success']) {
      state = state.copyWith(isLoading: false, isSuccess: true);
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result['message'],
        isSuccess: false,
      );
    }

    return result;
  }

  void reset() {
    state = LoginState();
  }
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return LoginNotifier(authService);
});

// State notifier for signup state
class SignUpState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  SignUpState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  SignUpState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return SignUpState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class SignUpNotifier extends StateNotifier<SignUpState> {
  final AuthService _authService;

  SignUpNotifier(this._authService) : super(SignUpState());

  Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String username,
    required String email,
    String cityState = '',
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authService.signUp(
      fullName: fullName,
      username: username,
      email: email,
      cityState: cityState,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (result['success']) {
      state = state.copyWith(isLoading: false, isSuccess: true);
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result['message'],
        isSuccess: false,
      );
    }

    return result;
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authService.signInWithGoogle();

    if (result['success']) {
      state = state.copyWith(isLoading: false, isSuccess: true);
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result['message'],
        isSuccess: false,
      );
    }

    return result;
  }

  void reset() {
    state = SignUpState();
  }
}

final signUpProvider =
    StateNotifierProvider<SignUpNotifier, SignUpState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return SignUpNotifier(authService);
});

// Provider for sign out functionality
final signOutProvider = Provider<Future<void> Function()>((ref) {
  final authService = ref.watch(authServiceProvider);
  return () async {
    await authService.signOut();
  };
});
