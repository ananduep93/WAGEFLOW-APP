import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Modern GoogleSignIn initialization for v7+
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Get user profile from Firestore
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint("Get User Profile Error: $e");
      return null;
    }
  }

  // Create user profile in Firestore
  Future<void> createUserProfile(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      debugPrint("Create User Profile Error: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await result.user?.updateDisplayName(name);
      
      return result;
    } catch (e) {
      debugPrint("Sign Up Error: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint("Sign In Error: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // In 7.x, authenticate() is the new way to trigger login UI
      // but signIn() might still be available as an alias or in some versions.
      // Based on the error, we'll try authenticate() or handle the missing accessToken.
      
      final googleUser = await _googleSignIn.authenticate();
      // googleUser is non-nullable in this context based on analysis errors
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      // For Firebase, only the idToken is strictly required for authentication.
      // The accessToken is optional and used for Google API access (not needed here).
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: null, // Set to null as it's separate in v7+
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint("Google Sign Out Error: $e");
    }
    await _auth.signOut();
  }
}
