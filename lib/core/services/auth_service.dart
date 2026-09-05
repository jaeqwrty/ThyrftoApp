import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:thryfto/core/services/database_service.dart';

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
        return {'success': false, 'message': 'We could not sign you in. Please try again.'};
      }

      final userData = await getUserProfile(user.uid);

      if (userData == null) {
        return {
          'success': false,
          'message': 'We could not find your Thryfto profile yet.',
        };
      }

      return {
        'success': true,
        'message': 'Login successful!',
        'user': userData,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'message': 'We could not sign you in right now. Please try again.',
      };
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
        return {
          'success': false,
          'message': availabilityResult['message'] ?? 'Username already taken',
        };
      }

      // Create user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {
          'success': false,
          'message': 'We could not create your account. Please try again.',
        };
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
        return {
          'success': false,
          'message': 'We could not finish your profile setup. Please try again.',
        };
      }

      final userData = {
        'id': user.uid,
        'uid': user.uid,
        'email': user.email,
        'fullName': fullName,
        'username': _normalizeUsername(username),
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
      return {
        'success': false,
        'message': 'We could not create your account right now. Please try again.',
      };
    }
  }

  /// Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Trigger the Google account picker
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '41459314240-5oml340uroesq50e7ri5ujbb1m16tef7.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // User cancelled the picker
      if (googleUser == null) {
        return {'success': false, 'message': 'Sign in cancelled'};
      }

      // Obtain auth tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Build Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign into Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user == null) {
        return {
          'success': false,
          'message': 'We could not sign you in with Google. Please try again.',
        };
      }

      // Check if Firestore profile already exists
      final existingProfile = await getUserProfile(user.uid);

      if (existingProfile != null) {
        // Returning user — just return their profile
        return {
          'success': true,
          'message': 'Welcome back!',
          'user': existingProfile,
          'isNewUser': false,
        };
      }

      // New Google user — create a minimal profile; onboarding will complete it
      final String displayName = user.displayName ?? '';
      final String email = user.email ?? '';

      // Derive a safe default username from the email prefix
      String rawUsername = email.split('@').first.toLowerCase();
      rawUsername = rawUsername.replaceAll(RegExp(r'[^a-z0-9_]'), '');
      if (rawUsername.isEmpty) rawUsername = 'user${user.uid.substring(0, 6)}';

      // Make sure username is unique by appending a suffix if needed
      String username = rawUsername;
      int suffix = 1;
      while (true) {
        final check = await isUsernameAvailable(username);
        if (check['available'] == true) break;
        username = '$rawUsername$suffix';
        suffix++;
      }

      final profileCreated = await createUserProfile(
        uid: user.uid,
        fullName: displayName.isNotEmpty ? displayName : username,
        username: username,
        email: email,
        cityState: '',
      );

      if (!profileCreated) {
        return {
          'success': false,
          'message': 'We could not finish your Google profile. Please try again.',
        };
      }

      final newProfile = await getUserProfile(user.uid);
      return {
        'success': true,
        'message': 'Account created! Complete your profile.',
        'user': newProfile,
        'isNewUser': true,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'message': 'Google sign-in was not completed. Please try again.',
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    // Also sign out from Google so the picker shows next time
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  String _normalizeUsername(String username) => username.trim().toLowerCase();

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(username);
  }

  Future<bool> _hasLegacyUsernameConflict(
    String normalizedUsername, {
    String? excludingUid,
  }) async {
    // Compatibility fallback for profiles created before username reservations.
    // This can be removed after all legacy profiles have reservation documents.
    final users = await _firestore.collection('users').get();
    return users.docs.any((doc) {
      if (doc.id == excludingUid) return false;
      final existing = doc.data()['username'];
      return existing is String &&
          _normalizeUsername(existing) == normalizedUsername;
    });
  }

  /// Check if username is available.
  Future<Map<String, dynamic>> isUsernameAvailable(String username) async {
    final normalizedUsername = _normalizeUsername(username);
    if (!_isValidUsername(normalizedUsername)) {
      return {
        'success': true,
        'available': false,
        'message':
            'Use 3-30 lowercase letters, numbers, or underscores only.',
      };
    }

    try {
      final reservation = await _firestore
          .collection('usernames')
          .doc(normalizedUsername)
          .get();
      if (reservation.exists) {
        return {'success': true, 'available': false};
      }

      final legacyConflict =
          await _hasLegacyUsernameConflict(normalizedUsername);
      return {
        'success': true,
        'available': !legacyConflict,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'We could not check that username right now. Please try again.',
      };
    }
  }

  /// Create a profile and reserve its normalized username atomically.
  Future<bool> createUserProfile({
    required String uid,
    required String fullName,
    required String username,
    required String email,
    required String cityState,
  }) async {
    final normalizedUsername = _normalizeUsername(username);
    if (!_isValidUsername(normalizedUsername)) return false;

    try {
      if (await _hasLegacyUsernameConflict(
        normalizedUsername,
        excludingUid: uid,
      )) {
        return false;
      }

      final userRef = _firestore.collection('users').doc(uid);
      final reservationRef =
          _firestore.collection('usernames').doc(normalizedUsername);

      await _firestore.runTransaction((transaction) async {
        final reservation = await transaction.get(reservationRef);
        final reservationOwner = reservation.data()?['uid'];
        if (reservation.exists && reservationOwner != uid) {
          throw StateError('Username already reserved');
        }

        transaction.set(reservationRef, {
          'uid': uid,
          'username': normalizedUsername,
          'updated_at': FieldValue.serverTimestamp(),
        });
        transaction.set(userRef, {
          'id': uid,
          'uid': uid,
          'fullName': fullName,
          'username': normalizedUsername,
          'username_normalized': normalizedUsername,
          'email': email,
          'cityState': cityState,
          'onboardingCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
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
    String? address,
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

      if (address != null && address.isNotEmpty) {
        data['cityState'] = address;
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

  /// Update user profile, reserving username changes atomically.
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

      if (fullName != null) updates['fullName'] = fullName.trim();
      if (bio != null) updates['bio'] = bio.trim();
      if (cityState != null) updates['cityState'] = cityState.trim();
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      final userRef = _firestore.collection('users').doc(uid);
      if (username == null) {
        await userRef.update(updates);
        return true;
      }

      final normalizedUsername = _normalizeUsername(username);
      if (!_isValidUsername(normalizedUsername)) return false;
      if (await _hasLegacyUsernameConflict(
        normalizedUsername,
        excludingUid: uid,
      )) {
        return false;
      }

      final newReservationRef =
          _firestore.collection('usernames').doc(normalizedUsername);

      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) throw StateError('User profile not found');

        final currentUsername = userSnapshot.data()?['username'];
        final currentNormalized = currentUsername is String
            ? _normalizeUsername(currentUsername)
            : '';
        final newReservation = await transaction.get(newReservationRef);

        DocumentReference<Map<String, dynamic>>? oldReservationRef;
        DocumentSnapshot<Map<String, dynamic>>? oldReservation;
        if (currentNormalized != normalizedUsername &&
            _isValidUsername(currentNormalized)) {
          oldReservationRef =
              _firestore.collection('usernames').doc(currentNormalized);
          oldReservation = await transaction.get(oldReservationRef);
        }

        final reservationOwner = newReservation.data()?['uid'];
        if (newReservation.exists && reservationOwner != uid) {
          throw StateError('Username already reserved');
        }

        transaction.set(newReservationRef, {
          'uid': uid,
          'username': normalizedUsername,
          'updated_at': FieldValue.serverTimestamp(),
        });
        transaction.update(userRef, {
          ...updates,
          'username': normalizedUsername,
          'username_normalized': normalizedUsername,
        });

        if (oldReservationRef != null &&
            oldReservation?.data()?['uid'] == uid) {
          transaction.delete(oldReservationRef);
        }
      });

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
          errorMessage =
              'We could not send the reset email right now. Please try again.';
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {
        'success': false,
        'message': 'We could not send the reset email right now. Please try again.',
      };
    }
  }

  Future<void> _deleteQueryDocuments(
    Query<Map<String, dynamic>> query,
  ) async {
    const batchSize = 400;
    while (true) {
      final snapshot = await query.limit(batchSize).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < batchSize) return;
    }
  }

  Future<bool> _reauthenticateForAccountDeletion(
    User user, {
    String? password,
  }) async {
    try {
      final providers = user.providerData.map((provider) => provider.providerId).toSet();

      if (providers.contains(EmailAuthProvider.PROVIDER_ID)) {
        final email = user.email;
        if (email == null || password == null || password.isEmpty) return false;

        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        return true;
      }

      if (providers.contains(GoogleAuthProvider.PROVIDER_ID)) {
        final googleSignIn = GoogleSignIn(
          serverClientId:
              '41459314240-5oml340uroesq50e7ri5ujbb1m16tef7.apps.googleusercontent.com',
        );
        final googleUser =
            await googleSignIn.signInSilently() ?? await googleSignIn.signIn();
        if (googleUser == null) return false;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
        return true;
      }

      return false;
    } catch (e) {
      print('Error reauthenticating for account deletion: $e');
      return false;
    }
  }

  Future<void> _cleanupOwnedAccountData(String userId) async {
    final databaseService = DatabaseService();
    final listings = await _firestore
        .collection('listings')
        .where('seller_id', isEqualTo: userId)
        .get();

    for (final listing in listings.docs) {
      final deleted = await databaseService.deleteListing(listing.id);
      if (!deleted) {
        throw Exception('Failed to delete listing ${listing.id}');
      }
    }

    await _deleteQueryDocuments(
      _firestore.collection('likes').where('userId', isEqualTo: userId),
    );
    await _deleteQueryDocuments(
      _firestore.collection('bookmarks').where('userId', isEqualTo: userId),
    );
    await _deleteQueryDocuments(
      _firestore.collection('favorites').where('user_id', isEqualTo: userId),
    );
    await _deleteQueryDocuments(
      _firestore.collection('favorites').where('seller_id', isEqualTo: userId),
    );
    await _deleteQueryDocuments(
      _firestore.collection('blocks').where('blocker_id', isEqualTo: userId),
    );
    await _deleteQueryDocuments(
      _firestore.collection('listing_shares').where('shared_by', isEqualTo: userId),
    );
    await _deleteQueryDocuments(
      _firestore.collection('listing_views').where('viewer_id', isEqualTo: userId),
    );
    await _deleteQueryDocuments(
      _firestore.collection('notifications').where('recipient_id', isEqualTo: userId),
    );
    await _deleteQueryDocuments(
      _firestore.collectionGroup('ratings').where('reviewer_id', isEqualTo: userId),
    );
    await _deleteQueryDocuments(
      _firestore.collection('usernames').where('uid', isEqualTo: userId),
    );
  }

  /// Delete the signed-in user's owned marketplace data and Firebase identity.
  /// Password accounts must provide their password so Firebase can require a
  /// fresh authentication before any destructive Firestore cleanup begins.
  Future<bool> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final reauthenticated = await _reauthenticateForAccountDeletion(
      user,
      password: password,
    );
    if (!reauthenticated) return false;

    final profileRef = _firestore.collection('users').doc(user.uid);
    final profileSnapshot = await profileRef.get();
    final profileData = profileSnapshot.data();

    try {
      await _cleanupOwnedAccountData(user.uid);
      await profileRef.delete();

      try {
        await user.delete();
      } catch (e) {
        // Keep Firestore/Auth state aligned when the final Auth deletion fails.
        if (profileData != null) {
          await profileRef.set(profileData);
        }
        rethrow;
      }

      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      return true;
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
        return 'We could not accept those sign-in details. Please try again.';
    }
  }
}
