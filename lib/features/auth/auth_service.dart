import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'user_model.dart';
import 'user_repository.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserRepository _userRepository = UserRepository();

  // Get current user
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('User canceled the sign-in or sign-in failed');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore, if not create a new user document
      try {
        final existingUser = await _userRepository.getUser(
          userCredential.user!.uid,
        );
        if (existingUser == null) {
          await _userRepository.createUserFromAuth(userCredential.user!);
        } else {
          // User exists
        }
      } catch (e) {
        debugPrint('Error checking/creating user in Firestore: $e');
        // Don't return null here, the sign-in was successful
      }
      return userCredential;
    } catch (e) {
      debugPrint('Error during Google sign-in: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      try {
        final existingUser = await _userRepository.getUser(
          userCredential.user!.uid,
        );
        if (existingUser == null) {
          await _userRepository.createUserFromAuth(userCredential.user!);
        } else {
          // User exists
        }
      } catch (e) {
        debugPrint('Error checking/creating user in Firestore: $e');
      }
      return userCredential;
    } catch (e) {
      debugPrint('Error during email sign-in: $e');
      throw Exception('Failed to sign in: : $e');
    }
  }

  // Register with email and password
  Future<UserCredential> createAccountWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (name.isNotEmpty) {
        await userCredential.user?.updateDisplayName(name);
      }
      await _userRepository.createUserFromAuth(userCredential.user!);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error during account creation: $e');
      throw Exception('Failed to create account: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error during account creation: $e');
      throw Exception('Failed to create account: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      return await _userRepository.getUser(uid);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Stream<UserModel?> streamUserProfile(String uid) {
    return _userRepository.streamUser(uid);
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _userRepository.updateUser(uid, data);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
}
