import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/database/auth_screen.dart' as db_auth;

/// IAuthService: Abstraction for authentication operations.
///
/// SOLID notes:
/// - Single Responsibility: keeps auth logic isolated from UI widgets.
/// - Open/Closed: new implementations can be added without modifying callers.
/// - Liskov Substitution: any implementation of `IAuthService` can replace
///   another one without changing client code.
/// - Interface Segregation: only auth-related methods are exposed here.
/// - Dependency Inversion: UI depends on this abstraction, not on concrete
///   implementations or static helpers.
abstract class IAuthService {
  Future<Map<String, dynamic>> login(String email, String password);

  Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String username,
    required String email,
    required String cityState,
    required String password,
    required String confirmPassword,
  });

  Future<List<Map<String, String>>> getAllUsers();
}

/// A simple, local/mock implementation of `IAuthService`.
///
/// This adapter delegates to the existing static `AuthService` in
/// `lib/database/auth_screen.dart`. In a real app you would provide a
/// production implementation here (e.g. Firebase, REST API) that also
/// implements `IAuthService`.
class MockAuthService implements IAuthService {
  const MockAuthService();

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Simulate network latency and return the existing static result.
    await Future.delayed(const Duration(milliseconds: 250));
    return db_auth.AuthService.login(email, password);
  }

  @override
  Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String username,
    required String email,
    required String cityState,
    required String password,
    required String confirmPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return db_auth.AuthService.signUp(
      fullName: fullName,
      username: username,
      email: email,
      cityState: cityState,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  @override
  Future<List<Map<String, String>>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return db_auth.AuthService.getAllUsers();
  }
}

/// Production Firebase implementation of `IAuthService`.
///
/// Uses Firebase Authentication for user login and registration,
/// and Cloud Firestore to store user profile data.
/// This follows Dependency Inversion—the UI depends on the abstraction,
/// allowing easy swapping between Firebase and mock implementations.
class FirebaseAuthService implements IAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuthService();

  /// Login with email and password using Firebase Authentication.
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Authentication failed'};
      }

      // Retrieve user profile from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return {'success': false, 'message': 'User profile not found'};
      }

      final userData = userDoc.data() ?? {};
      return {
        'success': true,
        'message': 'Login successful!',
        'user': {
          'uid': user.uid,
          'email': user.email,
          'fullName': userData['fullName'] ?? '',
          'username': userData['username'] ?? '',
          'cityState': userData['cityState'] ?? '',
        },
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getFirebaseErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Sign up with email and password using Firebase Authentication.
  /// Stores user profile data in Cloud Firestore.
  @override
  Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String username,
    required String email,
    required String cityState,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      // Validate inputs
      if (fullName.isEmpty ||
          username.isEmpty ||
          email.isEmpty ||
          cityState.isEmpty ||
          password.isEmpty ||
          confirmPassword.isEmpty) {
        return {'success': false, 'message': 'Please fill in all fields'};
      }

      if (password != confirmPassword) {
        return {'success': false, 'message': 'Passwords do not match'};
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters',
        };
      }

      // Check if username already exists
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        return {'success': false, 'message': 'Username already taken'};
      }

      // Create user account in Firebase Authentication
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Account creation failed'};
      }

      // Store user profile in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'fullName': fullName,
        'username': username,
        'email': email,
        'cityState': cityState,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Account created successfully!',
        'user': {
          'uid': user.uid,
          'email': user.email,
          'fullName': fullName,
          'username': username,
          'cityState': cityState,
        },
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getFirebaseErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Get all users from Firestore (for admin/testing purposes).
  @override
  Future<List<Map<String, String>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => {...doc.data().cast<String, String>(), 'uid': doc.id})
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Convert Firebase authentication error codes to user-friendly messages.
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled';
      default:
        return 'Authentication error: $code';
    }
  }
}
