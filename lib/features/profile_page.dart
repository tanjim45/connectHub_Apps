import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ============================================================
// PROFILE PAGE
// কাজ: Firebase থেকে login করা user-এর profile load ও display
// ============================================================

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Profile-এর তথ্যগুলো এখানে রাখা হবে।
  String userName = '';
  String nickname = '';
  String bio = '';
  String email = '';
  String? photoUrl;

  // Loading, saving ও error state।
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // আপাতত এগুলো demo posts; পরবর্তীতে real posts যুক্ত করা যাবে।
  final List<Map<String, dynamic>> posts = [
    {
      'title': 'Welcome to ConnectHub!',
      'color': Colors.blue,
      'icon': Icons.waving_hand,
    },
    {'title': 'Learning Flutter', 'color': Colors.purple, 'icon': Icons.code},
    {'title': 'Keep Growing', 'color': Colors.teal, 'icon': Icons.trending_up},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // প্রতিটি user-এর document হবে users/{নিজের UID}
  DocumentReference<Map<String, dynamic>> _profileReference(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Please log in to view your profile.';
      });

      return;
    }

    try {
      final reference = _profileReference(user.uid);

      final snapshot = await reference.get();

      final data = snapshot.data() ?? <String, dynamic>{};

      final savedName = (data['profileName'] ?? user.displayName ?? '')
          .toString()
          .trim();

      final loadedName = savedName.isEmpty ? 'ConnectHub User' : savedName;

      final loadedNickname = (data['nickname'] ?? '').toString();

      final loadedBio = (data['bio'] ?? '').toString();

      final loadedPhotoUrl = (data['photoUrl'] ?? user.photoURL)?.toString();

      if (!snapshot.exists) {
        await reference.set({
          'uid': user.uid,
          'profileName': loadedName,
          'nickname': loadedNickname,
          'bio': loadedBio,
          'email': user.email,
          'photoUrl': loadedPhotoUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      setState(() {
        userName = loadedName;
        nickname = loadedNickname;
        bio = loadedBio;
        email = user.email ?? '';
        photoUrl = loadedPhotoUrl;

        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      debugPrint('Profile load error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Could not load your profile. Check your internet connection and Firestore rules.';
      });
    }
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in first.');
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _EditProfileDialog(
        initialName: userName,
        initialNickname: nickname,
        initialBio: bio,
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _profileReference(user.uid).set({
        'uid': user.uid,
        'profileName': result['profileName']!,
        'nickname': result['nickname']!,
        'bio': result['bio']!,
        'email': user.email,
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      try {
        await user.updateDisplayName(result['profileName']);
      } catch (error) {
        debugPrint('Display name sync error: $error');
      }

      if (!mounted) return;

      setState(() {
        userName = result['profileName']!;
        nickname = result['nickname']!;
        bio = result['bio']!;
      });

      _showMessage('Profile updated successfully!');
    } catch (error) {
      debugPrint('Profile save error: $error');

      if (mounted) {
        _showMessage('Could not save your profile. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Logout করার আগে user-এর confirmation নেওয়া হবে।
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.logout_rounded,
            color: Theme.of(dialogContext).colorScheme.error,
            size: 32,
          ),
          title: const Text('Log Out?'),
          content: const Text(
            'Are you sure you want to log out of ConnectHub?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      // AuthGate-এর authStateChanges() নিজে থেকেই Welcome Page দেখাবে।
    } catch (error) {
      debugPrint('Logout error: $error');

      if (mounted) {
        _showMessage('Could not log out. Please try again.');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // PROFILE UI
  // ============================================================

  Widget _buildHeader(ThemeData theme, ColorScheme colors, String handle) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Column(
      children: [
        // Banner + avatar
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 130,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primary, colors.tertiary],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -30,
                    right: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -20,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -52,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.scaffoldBackgroundColor,
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: colors.primaryContainer,
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                  child: hasPhoto
                      ? null
                      : Icon(
                          Icons.person,
                          size: 60,
                          color: colors.onPrimaryContainer,
                        ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 62),

        Text(
          userName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            handle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        if (email.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mail_outline,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  email,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            bio.isEmpty ? 'No bio added yet.' : bio,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
              color: bio.isEmpty ? colors.onSurfaceVariant : null,
              fontStyle: bio.isEmpty ? FontStyle.italic : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(ThemeData theme, ColorScheme colors) {
    final divider = Container(
      width: 1,
      height: 34,
      color: colors.outlineVariant,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStat(context, 'Posts', '${posts.length}')),
          divider,
          Expanded(child: _buildStat(context, 'Followers', '128')),
          divider,
          Expanded(child: _buildStat(context, 'Following', '96')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_circle_outlined,
                  size: 42,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final handle = nickname.isNotEmpty
        ? '@$nickname'
        : '@${userName.toLowerCase().replaceAll(RegExp(r'\s+'), '')}';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    // Title + Logout
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'My Profile',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text('Logout'),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.error,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    _buildHeader(theme, colors, handle),

                    const SizedBox(height: 22),

                    _buildStatsCard(theme, colors),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _isSaving ? null : _editProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.edit_outlined),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Edit Profile',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.grid_view_rounded,
                            size: 20,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'My Posts',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Posts grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = posts[index];
                  final color = post['color'] as Color;
                  final icon = post['icon'] as IconData;

                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.20),
                          color.withValues(alpha: 0.07),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 32, color: color),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            post['title'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: posts.length),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width >= 700 ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EDIT PROFILE DIALOG
// Controllers এই widget-এর নিজের state-এ থাকে এবং dispose() এ বন্ধ হয়।
// ============================================================

class _EditProfileDialog extends StatefulWidget {
  final String initialName;
  final String initialNickname;
  final String initialBio;

  const _EditProfileDialog({
    required this.initialName,
    required this.initialNickname,
    required this.initialBio,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);
    _nicknameController = TextEditingController(text: widget.initialNickname);
    _bioController = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _bioController.dispose();

    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop({
      'profileName': _nameController.text.trim(),
      'nickname': _nicknameController.text.trim().replaceFirst(
        RegExp(r'^@+'),
        '',
      ),
      'bio': _bioController.text.trim(),
    });
  }

  InputDecoration _decoration({
    required String label,
    required String hint,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      alignLabelWithHint: alignLabelWithHint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.edit_outlined, color: colors.onPrimaryContainer),
      ),
      title: const Text('Edit Profile'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  maxLength: 30,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration(
                    label: 'Profile Name',
                    hint: 'Enter your name',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';

                    if (name.isEmpty) {
                      return 'Profile name is required.';
                    }

                    if (name.length < 2) {
                      return 'Enter at least 2 characters.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _nicknameController,
                  maxLength: 20,
                  decoration: _decoration(
                    label: 'Nickname',
                    hint: 'e.g. tanjim45',
                    icon: Icons.alternate_email,
                  ),
                  validator: (value) {
                    final nick = (value ?? '').trim().replaceFirst(
                      RegExp(r'^@+'),
                      '',
                    );

                    if (nick.isEmpty) return null;

                    if (!RegExp(r'^[a-zA-Z0-9_.]{3,20}$').hasMatch(nick)) {
                      return 'Use 3–20 letters, numbers, . or _.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _bioController,
                  maxLength: 120,
                  maxLines: 3,
                  decoration: _decoration(
                    label: 'Bio',
                    hint: 'Tell people about yourself...',
                    icon: Icons.info_outline,
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saveProfile,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    );
  }
}