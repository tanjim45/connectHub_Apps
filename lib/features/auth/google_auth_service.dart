import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;

  Future<UserCredential> signInWithGoogle() async {
    UserCredential credential;

    if (kIsWeb) {
      // Web: Firebase Authentication-এর Google popup
      final provider = GoogleAuthProvider();
      provider.addScope('email');

      credential = await _auth.signInWithPopup(provider);
    } else {
      // Android: google_sign_in 7.2.0 API
      if (!_initialized) {
        await GoogleSignIn.instance.initialize();
        _initialized = true;
      }

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final oauthCredential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      credential = await _auth.signInWithCredential(oauthCredential);
    }

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Google sign-in did not return a user.',
      );
    }

    // Firestore-এ user profile তৈরি বা update
    final profileRef = _firestore.collection('users').doc(user.uid);
    final profileSnapshot = await profileRef.get();

    final existingData = profileSnapshot.data() ?? <String, dynamic>{};

    await profileRef.set({
      'uid': user.uid,
      'profileName': existingData['profileName'] ??
          user.displayName ??
          'ConnectHub User',
      'nickname': existingData['nickname'] ?? '',
      'bio': existingData['bio'] ?? '',
      'email': user.email,
      'photoUrl': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!profileSnapshot.exists)
        'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return credential;
  }
}