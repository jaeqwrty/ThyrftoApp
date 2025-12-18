import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Authentication failed'};
      }

      final userData = await getUserProfile(user.uid);

      if (userData == null) {
        return {'success': false, 'message': 'User profile not found'};
      }

      return {
        'success': true,
        'message': 'Login successful!',
        'user': userData,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// Sign up with email and password
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
          password.isEmpty) {
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

      // Check if username is available
      final isAvailable = await isUsernameAvailable(username);
      if (!isAvailable) {
        return {'success': false, 'message': 'Username already taken'};
      }

      // Create user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Account creation failed'};
      }

      // Save user profile to database
      final profileCreated = await createUserProfile(
        uid: user.uid,
        fullName: fullName,
        username: username,
        email: email,
        cityState: cityState,
      );

      if (!profileCreated) {
        await user.delete();
        return {'success': false, 'message': 'Failed to create user profile'};
      }

      final userData = {
        'id': user.uid,
        'uid': user.uid,
        'email': user.email,
        'fullName': fullName,
        'username': username,
        'cityState': cityState,
      };

      return {
        'success': true,
        'message': 'Account created successfully!',
        'user': userData,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Create user profile in Firestore
  Future<bool> createUserProfile({
    required String uid,
    required String fullName,
    required String username,
    required String email,
    required String cityState,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'id': uid,
        'uid': uid,
        'fullName': fullName,
        'username': username,
        'email': email,
        'cityState': cityState,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Convert Firebase error codes to user-friendly messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
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
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'Authentication error occurred';
    }
  }
}
