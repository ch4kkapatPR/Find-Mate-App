
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class UserService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static String? get uid => _auth.currentUser?.uid;

  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final currentUid = uid;

    if (currentUid == null) {
      return null;
    }

    final doc = await _firestore
        .collection('users')
        .doc(currentUid)
        .get();

    if (!doc.exists) {
      return null;
    }

    return doc.data();
  }

  static Future<void> updateProfile({
    required String name,
    required String bio,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('ไม่พบผู้ใช้งาน');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name.trim(),
      'email': user.email ?? '',
      'bio': bio.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.updateDisplayName(name.trim());
  }
}