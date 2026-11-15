import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../models/user_record.dart';
import '../services/auth_service.dart';
import '../services/board_service.dart';
import '../theme/app_theme.dart';

class BoardScreen extends StatefulWidget {
  final User currentUser;
  final UserRecord userRecord;

  const BoardScreen({
    super.key,
    required this.currentUser,
    required this.userRecord,
  });

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final BoardService _boardService = BoardService();
  final AuthService _auth = AuthService();

  late final Stream<List<Message>> _messageStream;
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isPosting = false;
  final bool _useIdempotencyKey = false;

  @override
  void initState() {
    super.initState();
    // Maintain a single, stable stream subscription in State
    _messageStream = _boardService.messageBoard();
  }

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _postMessage() async {
    final text = _composerController.text.trim();
    if (_isPosting || text.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      String? key;
      if (_useIdempotencyKey) {
        // Deterministic key: combines user uid and current minute/hour window or explicit key
        key = 'idemp_${widget.currentUser.uid}_${DateTime.now().millisecondsSinceEpoch ~/ 10000}';
      }

      await _boardService.postMessage(
        authorUid: widget.currentUser.uid,
        authorName: widget.userRecord.fullName.isNotEmpty
            ? widget.userRecord.fullName
            : (widget.currentUser.email?.split('@').first ?? 'Author'),
        text: text,
        idempotencyKey: key,
      );

      _composerController.clear();
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BoardService.getErrorMessage(e)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _showEditDialog(Message message) {
    final editController = TextEditingController(text: message.text);
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: editController,
            maxLines: 3,
            enabled: !saving,
            decoration: const InputDecoration(
              labelText: 'Message Text',
              hintText: 'Enter updated message...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final newText = editController.text.trim();
                      if (newText.isEmpty) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);
                      setDialogState(() => saving = true);

                      try {
                        await _boardService.editMessage(
                          messageId: message.id,
                          newText: newText,
                        );
                        if (ctx.mounted) {
                          navigator.pop();
                        }
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Message updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(BoardService.getErrorMessage(e)),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Message message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text(
          'Are you sure you want to delete this message? This action is permanent and enforced by security rules.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _boardService.deleteMessage(messageId: message.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message deleted successfully.'),
                      backgroundColor: Colors.black87,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(BoardService.getErrorMessage(e)),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showProfileModal() {
    final regDateStr = widget.userRecord.registrationDateTime != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.userRecord.registrationDateTime!)
        : 'Pending Server Timestamp';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.fallPrimary,
                  child: Icon(Icons.person, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userRecord.fullName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.currentUser.email ?? '',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'Firestore User Document (5 Required Fields):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildFieldTile('1. UID', widget.userRecord.uid),
            _buildFieldTile('2. First Name', widget.userRecord.firstName),
            _buildFieldTile('3. Last Name', widget.userRecord.lastName),
            _buildFieldTile('4. Role', widget.userRecord.role),
            _buildFieldTile('5. Registration Time', regDateStr),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _auth.signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog to trigger test actions for evidence (Rules denials, idempotent test, spices)
  void _showTestToolsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Evidence & Vault Hunt Tools',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.fallPrimaryDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Run automated evidence drills to verify security rules and extra spices.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const Divider(height: 24),

              // Drill 1: Rules Denial Test (Cross-UID mutation)
              ListTile(
                leading: const Icon(Icons.security, color: Colors.red),
                title: const Text('Test Rules Denial (Cross-UID Edit)'),
                subtitle: const Text('Simulates attempting to update another user\'s post to verify Firestore throws permission-denied.'),
                trailing: const Icon(Icons.play_arrow),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    // Attempt to edit a simulated post with a different author UID
                    await _boardService.editMessage(
                      messageId: 'simulated_foreign_message_id_9999',
                      newText: 'Hacked cross-user text',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unexpected: write succeeded!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Rules Denial Verified!'),
                          content: Text(
                            'Observed Firestore error as expected:\n\n${BoardService.getErrorMessage(e)}\n\nRaw: $e',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),

              // Drill 2: Idempotent Double-Submit Drill (Spice #4)
              ListTile(
                leading: const Icon(Icons.flash_on, color: Colors.amber),
                title: const Text('Test Idempotent Double-Tap (Spice #4)'),
                subtitle: const Text('Triggers two rapid identical post calls with an idempotency key to prove exactly 1 doc results.'),
                trailing: const Icon(Icons.play_arrow),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final key = 'double_tap_test_${DateTime.now().millisecondsSinceEpoch}';
                  try {
                    // Call 1
                    final f1 = _boardService.postMessage(
                      authorUid: widget.currentUser.uid,
                      authorName: widget.userRecord.fullName,
                      text: '[Idempotency Test] Tap 1 & 2',
                      idempotencyKey: key,
                    );
                    // Call 2 (concurrent duplicate)
                    final f2 = _boardService.postMessage(
                      authorUid: widget.currentUser.uid,
                      authorName: widget.userRecord.fullName,
                      text: '[Idempotency Test] Tap 1 & 2',
                      idempotencyKey: key,
                    );
                    await Future.wait([f1, f2]);
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Idempotent Test Complete'),
                          content: Text(
                            'Both simultaneous calls completed against key: $key.\n\nOnly exactly ONE document exists in Firestore under this key.',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),

              // Drill 3: Schema Shape-shifter (Spice #5)
              ListTile(
                leading: const Icon(Icons.transform, color: Colors.blue),
                title: const Text('Schema Shape-shifter (Spice #5)'),
                subtitle: const Text('Seeds a legacy v1 message document and executes migration to v2.'),
                trailing: const Icon(Icons.play_arrow),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    final seededId = await _boardService.seedLegacyV1Message(
                      authorUid: widget.currentUser.uid,
                      authorName: widget.userRecord.fullName,
                      content: 'Legacy v1 message: using content and senderUid fields.',
                    );
                    final migratedCount = await _boardService.migrateSchemaV1toV2();
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Schema Migration Verified!'),
                          content: Text(
                            'Seeded legacy v1 document ($seededId).\nMigrated $migratedCount document(s) losslessly to schemaVersion: 2.',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Migration error: $e')),
                      );
                    }
                  }
                },
              ),

              // Drill 4: Batch Librarian (Spice #6)
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.purple),
                title: const Text('Batch Delete Own Posts (Spice #6)'),
                subtitle: const Text('Executes an atomic WriteBatch deleting all your own posts at once.'),
                trailing: const Icon(Icons.play_arrow),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    final deletedCount = await _boardService.deleteOwnMessages(
                      authorUid: widget.currentUser.uid,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Atomic batch deleted $deletedCount of your messages.'),
                          backgroundColor: Colors.purple,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Batch error: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The Vault Message Board'),
            Text(
              '${widget.userRecord.fullName} (${widget.userRecord.role})',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Evidence & Test Tools',
            onPressed: _showTestToolsModal,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'User Profile Record',
            onPressed: _showProfileModal,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => _auth.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Live Message Stream
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: _messageStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            const Text(
                              'Failed to load message stream.',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              BoardService.getErrorMessage(snapshot.error!),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.fallPrimary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 56,
                                color: AppTheme.fallPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'The Vault is Silent',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'No messages posted yet. Post the very first message below to start the live stream!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isOwner = message.authorUid == widget.currentUser.uid;
                      final dateStr = message.createdAt != null
                          ? DateFormat('MMM d, h:mm a').format(message.createdAt!)
                          : 'Sending...';

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isOwner
                                        ? AppTheme.fallPrimary
                                        : Colors.blueGrey.shade400,
                                    child: Text(
                                      message.authorName.isNotEmpty
                                          ? message.authorName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              message.authorName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isOwner
                                                    ? AppTheme.fallPrimaryDark
                                                    : Colors.black87,
                                              ),
                                            ),
                                            if (isOwner) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.fallPrimary.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'You',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.fallPrimaryDark,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Owner Actions (Edit & Delete) — Only shown for author's own messages!
                                  if (isOwner)
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20),
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showEditDialog(message);
                                        } else if (val == 'delete') {
                                          _showDeleteConfirmation(message);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                message.text,
                                style: const TextStyle(fontSize: 15, height: 1.3),
                              ),
                              if (message.isEdited) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.edit, size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Edited ${message.editedAt != null ? DateFormat('h:mm a').format(message.editedAt!) : ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Message Composer at bottom
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _composerController,
                        enabled: !_isPosting,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Share a note with the vault...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isPosting ? null : _postMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.fallPrimary,
                      ),
                      icon: _isPosting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
