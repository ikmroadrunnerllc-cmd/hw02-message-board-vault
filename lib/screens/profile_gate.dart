import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_record.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'board_screen.dart';

class ProfileGate extends StatefulWidget {
  final User user;
  const ProfileGate({super.key, required this.user});

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  final UserService _userService = UserService();
  final AuthService _auth = AuthService();

  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  String _selectedRole = 'Student';
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await _userService.saveUserRecord(
        widget.user,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        role: _selectedRole,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserRecord?>(
      stream: _userService.userRecordStream(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile Status'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _auth.signOut(),
                  tooltip: 'Sign Out',
                ),
              ],
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 54, color: Colors.orange),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load your profile record.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userRecord = snapshot.data;

        // Verify that all 5 required fields are present
        final hasAllFields = userRecord != null &&
            userRecord.uid.isNotEmpty &&
            userRecord.firstName.isNotEmpty &&
            userRecord.lastName.isNotEmpty &&
            userRecord.role.isNotEmpty &&
            userRecord.registrationDateTime != null;

        if (hasAllFields) {
          return BoardScreen(
            currentUser: widget.user,
            userRecord: userRecord,
          );
        }

        // Profile is missing or incomplete: show completion/retry form
        return Scaffold(
          appBar: AppBar(
            title: const Text('Complete Your Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _auth.signOut(),
                tooltip: 'Sign Out',
              ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.account_circle_outlined,
                        size: 64,
                        color: AppTheme.fallPrimary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Account Created, Profile Incomplete',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.fallPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your sign-in succeeded, but the 5-field Firestore user record is not yet complete. Please finish setting up your record below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _firstName,
                        enabled: !_saving,
                        decoration: const InputDecoration(labelText: 'First Name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastName,
                        enabled: !_saving,
                        decoration: const InputDecoration(labelText: 'Last Name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: ['Student', 'Faculty', 'Staff', 'Researcher', 'Alumni', 'Member']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: _saving ? null : (v) => setState(() => _selectedRole = v ?? 'Student'),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saving ? null : _completeProfile,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Save User Record & Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
