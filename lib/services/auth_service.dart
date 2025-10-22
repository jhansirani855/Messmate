import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ==============================
  /// SIGN UP USER
  /// ==============================
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String dob,
  }) async {
    try {
      // Create Firebase Auth user
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      if (user != null) {
        // Save user details in Firestore
        await _db.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'dob': dob,
          'role': 'user', // default role
        });
      }

      return user;
    } catch (e) {
      print('Signup Error: $e');
      return null;
    }
  }

  /// ==============================
  /// SIGN IN USER / ADMIN
  /// ==============================
  Future<String?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      if (user != null) {
        final doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc['role']; // returns "user" or "admin"
        } else {
          return null; // role not found
        }
      } else {
        return null;
      }
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  /// ==============================
  /// SIGN OUT USER
  /// ==============================
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// ==============================
  /// GET CURRENT USER
  /// ==============================
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
