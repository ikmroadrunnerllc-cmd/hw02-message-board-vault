import 'package:cloud_firestore/cloud_firestore.dart';

class UserRecord {
  final String uid;
  final String firstName;
  final String lastName;
  final String role;
  final DateTime? registrationDateTime;

  UserRecord({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.registrationDateTime,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory UserRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('User document does not exist.');
    }

    DateTime? regTime;
    final rawRegTime = data['registrationDateTime'];
    if (rawRegTime is Timestamp) {
      regTime = rawRegTime.toDate();
    } else if (rawRegTime is String) {
      regTime = DateTime.tryParse(rawRegTime);
    }

    return UserRecord(
      uid: data['uid'] as String? ?? snapshot.id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      role: data['role'] as String? ?? 'Member',
      registrationDateTime: regTime,
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'registrationDateTime': forCreate ? FieldValue.serverTimestamp() : (registrationDateTime != null ? Timestamp.fromDate(registrationDateTime!) : FieldValue.serverTimestamp()),
    };
  }
}
