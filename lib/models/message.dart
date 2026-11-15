import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String authorUid;
  final String authorName;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final int schemaVersion;

  const Message({
    required this.id,
    required this.text,
    required this.authorUid,
    required this.authorName,
    this.createdAt,
    this.editedAt,
    this.schemaVersion = 2,
  });

  bool get isEdited => editedAt != null;

  factory Message.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Message document data is null.');
    }

    DateTime? parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    // Support both schema v1 ('content') and schema v2 ('text')
    final text = data['text'] as String? ?? data['content'] as String? ?? '';
    final authorUid = data['authorUid'] as String? ?? data['senderUid'] as String? ?? '';
    final authorName = data['authorName'] as String? ?? data['senderName'] as String? ?? 'Anonymous';
    final version = data['schemaVersion'] as int? ?? 1;

    return Message(
      id: snapshot.id,
      text: text,
      authorUid: authorUid,
      authorName: authorName,
      createdAt: parseTimestamp(data['createdAt']),
      editedAt: parseTimestamp(data['editedAt']),
      schemaVersion: version,
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'text': text,
      'authorUid': authorUid,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
      'schemaVersion': schemaVersion,
    };
  }
}
