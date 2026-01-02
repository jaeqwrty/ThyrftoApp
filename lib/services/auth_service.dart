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
        email: email.trim(),
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
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String username,
    required String email,
    String cityState = '', // Optional with default empty string
    required String password,
    required String confirmPassword,
  }) async {
    try {
      // Validate inputs (cityState removed from validation)
      if (fullName.isEmpty ||
          username.isEmpty ||
          email.isEmpty ||
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
      final availabilityResult = await isUsernameAvailable(username);
      if (!availabilityResult['success']) {
        return {
          'success': false,
          'message':
              'Network error checking username. Please check your connection.'
        };
      }

      if (!availabilityResult['available']) {
        return {'success': false, 'message': 'Username already taken'};
      }

      // Create user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
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
  Future<Map<String, dynamic>> isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      return {
        'success': true,
        'available': querySnapshot.docs.isEmpty,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking username availability: $e',
      };
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
        'onboardingCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error creating user profile: $e');
      return false;
    }
  }

  /// Complete onboarding
  Future<bool> completeOnboarding({
    required String uid,
    required String bio,
    String? profileImageUrl,
  }) async {
    try {
      final data = {
        'bio': bio,
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (profileImageUrl != null) {
        data['profileImageUrl'] = profileImageUrl;
      }

      await _firestore.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      print('Error completing onboarding: $e');
      return false;
    }
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          data['id'] = doc.id;
          data['uid'] = userId;
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['onboardingCompleted'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile({
    required String uid,
    String? fullName,
    String? username,
    String? bio,
    String? cityState,
    String? profileImageUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (fullName != null) {
        updates['fullName'] = fullName.trim();
        updates['full_name'] =
            fullName.trim(); // Support both naming conventions
      }

      if (username != null) {
        // Check if username is already taken by another user
        final usernameQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: username.toLowerCase())
            .limit(1)
            .get();

        if (usernameQuery.docs.isNotEmpty &&
            usernameQuery.docs.first.id != uid) {
          return false; // Username taken
        }
        updates['username'] = username.trim().toLowerCase();
      }

      if (bio != null) updates['bio'] = bio.trim();
      if (cityState != null) updates['cityState'] = cityState.trim();

      // Handle profile image URL - this is the important fix
      if (profileImageUrl != null) {
        if (profileImageUrl.isEmpty) {
          // Explicitly remove the profile image by setting to empty string
          updates['profileImageUrl'] = '';
        } else {
          // Update with new image URL
          updates['profileImageUrl'] = profileImageUrl;
        }
      }

      await _firestore.collection('users').doc(uid).update(updates);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  /// Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        return {'success': false, 'message': 'Please enter your email'};
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        default:
          errorMessage = 'Failed to send reset email: ${e.message}';
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete user from Firebase Auth
        await user.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
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
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      default:
        return 'Authentication error occurred';
    }
  }
}
