import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _role;
  String? get role => _role;

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

    try {
      await _db.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _role = 'customer';
      _isAuthenticated = true;

      notifyListeners();
    } catch (e) {
      // Jika penyimpanan profil gagal, keluar dari akun
      await _auth.signOut();

      _isAuthenticated = false;
      _role = null;

      notifyListeners();

      rethrow;
    }
  }

  // LOGIN
  Future<void> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('User tidak ditemukan.');
    }

    try {
      final doc = await _db
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        throw Exception(
          'Profil user tidak ditemukan di Firestore.',
        );
      }

      final data = doc.data();
      final userRole = data?['role'];

      if (userRole != 'admin' && userRole != 'customer') {
        throw Exception('Role akun tidak valid.');
      }

      _role = userRole as String;
      _isAuthenticated = true;

      notifyListeners();
    } catch (e) {
      await _auth.signOut();

      _isAuthenticated = false;
      _role = null;

      notifyListeners();

      rethrow;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();

    _isAuthenticated = false;
    _role = null;

    notifyListeners();
  }
}
