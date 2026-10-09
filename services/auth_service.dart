import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  // สมัครสมาชิก
  static Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential =
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await user.updateDisplayName(name.trim());

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return credential;
  }

  // เข้าสู่ระบบ
  static Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ออกจากระบบ
  static Future<void> logout() async {
    await _auth.signOut();
  }
}