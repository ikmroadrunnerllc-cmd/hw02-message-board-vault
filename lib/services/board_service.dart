import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class BoardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _messagesCol =>
      _db.collection('messages');

  /// CREATE — uid-owned, server-timestamped message.
  /// If [idempotencyKey] is provided (Spice #4: Idempotent Alchemist),
  /// uses a deterministic doc ID or transaction to guarantee exactly one document.
  Future<String> postMessage({
    required String authorUid,
    required String authorName,
    required String text,
    String? idempotencyKey,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      throw ArgumentError('Message text cannot be empty.');
    }

    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      // Deterministic idempotency guard: doc keyed by idempotencyKey
      final docRef = _messagesCol.doc(idempotencyKey);
      await docRef.set({
        'authorUid': authorUid,
        'authorName': authorName,
        'text': cleanText,
        'createdAt': FieldValue.serverTimestamp(),
        'schemaVersion': 2,
      }, SetOptions(merge: false));
      return docRef.id;
    } else {
      final docRef = await _messagesCol.add({
        'authorUid': authorUid,
        'authorName': authorName,
        'text': cleanText,
        'createdAt': FieldValue.serverTimestamp(),
        'schemaVersion': 2,
      });
      return docRef.id;
    }
  }

  /// READ (live stream) — the board renders from this snapshots() stream.
  /// Subscribes to collection ordered by 'createdAt' ascending (oldest to newest).
  Stream<List<Message>> messageBoard({int limit = 100}) {
    return _messagesCol
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  /// UPDATE — own message only (enforced by security rules).
  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    final cleanText = newText.trim();
    if (cleanText.isEmpty) {
      throw ArgumentError('Updated text cannot be empty.');
    }

    await _messagesCol.doc(messageId).update({
      'text': cleanText,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// DELETE — own message only (enforced by security rules).
  Future<void> deleteMessage({required String messageId}) async {
    await _messagesCol.doc(messageId).delete();
  }

  /// SPICE #6 (Batch Librarian) — Delete all own messages in an atomic WriteBatch.
  Future<int> deleteOwnMessages({required String authorUid}) async {
    final query = await _messagesCol
        .where('authorUid', isEqualTo: authorUid)
        .get();

    if (query.docs.isEmpty) return 0;

    final batch = _db.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return query.docs.length;
  }

  /// SPICE #5 (Schema Shape-shifter) — Seed a legacy v1 message for migration test.
  Future<String> seedLegacyV1Message({
    required String authorUid,
    required String authorName,
    required String content,
  }) async {
    final docRef = await _messagesCol.add({
      'senderUid': authorUid,
      'senderName': authorName,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'schemaVersion': 1,
    });
    return docRef.id;
  }

  /// SPICE #5 (Schema Shape-shifter) — Migrate legacy v1 messages to v2.
  Future<int> migrateSchemaV1toV2() async {
    final query = await _messagesCol
        .where('schemaVersion', isEqualTo: 1)
        .get();

    if (query.docs.isEmpty) return 0;

    final batch = _db.batch();
    for (final doc in query.docs) {
      final data = doc.data();
      final text = data['text'] ?? data['content'] ?? '';
      final authorUid = data['authorUid'] ?? data['senderUid'] ?? '';
      final authorName = data['authorName'] ?? data['senderName'] ?? '';

      batch.update(doc.reference, {
        'text': text,
        'authorUid': authorUid,
        'authorName': authorName,
        'schemaVersion': 2,
        'migratedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return query.docs.length;
  }

  /// Helper to translate Firestore exceptions into clear user messages.
  static String getErrorMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permission Denied: Security rules prevented this operation. You can only edit or delete your own posts.';
        case 'unavailable':
          return 'Service temporarily unavailable. Check your connection or offline cache.';
        case 'not-found':
          return 'Message document was not found.';
        default:
          return error.message ?? 'Firestore error (${error.code}).';
      }
    }
    return error.toString();
  }
}
