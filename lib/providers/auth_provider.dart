
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  User? get currentUser => _auth.currentUser;

  // REGISTER
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Gagal membuat akun.');
    }

    await _db.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _isAuthenticated = true;
    notifyListeners();
  }

  // LOGIN
  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    _isAuthenticated = true;
    notifyListeners();
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();

    _isAuthenticated = false;
    notifyListeners();
  }
}
