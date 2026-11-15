import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_record.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  /// Writes one user document on registration with all 5 required fields.
  Future<void> saveUserRecord(
    User user, {
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    final docRef = _usersCol.doc(user.uid);
    await docRef.set({
      'uid': user.uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'role': role.trim(),
      'registrationDateTime': FieldValue.serverTimestamp(),
    });
  }

  /// Fetches the user record document for the specified UID.
  Future<UserRecord?> getUserRecord(String uid) async {
    final snapshot = await _usersCol.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserRecord.fromFirestore(snapshot);
  }

  /// Live stream of user record for dynamic UI updates.
  Stream<UserRecord?> userRecordStream(String uid) {
    return _usersCol.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserRecord.fromFirestore(snapshot);
    });
  }

  /// Verifies whether the required 5-field user record is present in Firestore.
  Future<bool> hasCompleteProfile(String uid) async {
    try {
      final doc = await _usersCol.doc(uid).get();
      if (!doc.exists) return false;
      final data = doc.data();
      if (data == null) return false;
      return (data['uid'] != null &&
          data['firstName'] != null &&
          data['lastName'] != null &&
          data['role'] != null &&
          data['registrationDateTime'] != null);
    } catch (_) {
      return false;
    }
  }
}
