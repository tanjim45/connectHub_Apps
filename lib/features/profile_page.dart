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

    // Profile page খোলার সময় Firebase থেকে তথ্য আনবে।
    _loadProfile();
  }

  // ============================================================
  // FIRESTORE DOCUMENT REFERENCE
  // প্রতিটি user-এর document হবে users/{নিজের UID}
  // ============================================================

  DocumentReference<Map<String, dynamic>> _profileReference(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  // ============================================================
  // LOAD PROFILE
  // কাজ: Firebase Auth থেকে user নেওয়া এবং Firestore থেকে
  // তাঁর Profile Name, Nickname, Bio ও Photo URL load করা।
  // ============================================================

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    // Login করা user না থাকলে error দেখাবে।
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

      // Firestore থেকে নিজের profile document পড়া।
      final snapshot = await reference.get();

      final data = snapshot.data() ?? <String, dynamic>{};

      // Firestore-এ নাম না থাকলে Firebase Auth-এর নাম ব্যবহার।
      final savedName = (data['profileName'] ?? user.displayName ?? '')
          .toString()
          .trim();

      final loadedName = savedName.isEmpty ? 'ConnectHub User' : savedName;

      final loadedNickname = (data['nickname'] ?? '').toString();

      final loadedBio = (data['bio'] ?? '').toString();

      final loadedPhotoUrl = (data['photoUrl'] ?? user.photoURL)?.toString();

      // আগে profile document তৈরি না হয়ে থাকলে তৈরি করবে।
      // সাধারণত Sign Up-এর সময়ই এটি তৈরি হওয়ার কথা।
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

      // পাওয়া তথ্যগুলো screen-এ দেখানোর জন্য state-এ রাখা।
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
  // কাজ: Dialog খুলবে, user-এর পরিবর্তিত তথ্য নেবে এবং Firestore-
  // এ save করবে। TextEditingController dialog নিজে পরিচালনা করবে।
  // তাই আগের disposed-controller error হবে না।
  // ============================================================

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in first.');
      return;
    }

    // আলাদা StatefulWidget ব্যবহার করা হয়েছে।
    // Dialog বন্ধ হলে তার controllers নিজে dispose হবে।
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _EditProfileDialog(
        initialName: userName,
        initialNickname: nickname,
        initialBio: bio,
      ),
    );

    // Cancel করলে কোনো data save হবে না।
    if (!mounted || result == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // পরিবর্তিত profile data Firestore-এ save করা হচ্ছে।
      // merge: true থাকায় অন্য existing fields মুছে যাবে না।
      await _profileReference(user.uid).set({
        'uid': user.uid,
        'profileName': result['profileName']!,
        'nickname': result['nickname']!,
        'bio': result['bio']!,
        'email': user.email,
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Firebase Authentication-এর display name-টিও update।
      // Firestore save সফল হলেও Auth name update ব্যর্থ হলে
      // সেটির কারণে profile save-কে ব্যর্থ দেখানো হবে না।
      try {
        await user.updateDisplayName(result['profileName']);
      } catch (error) {
        debugPrint('Display name sync error: $error');
      }

      if (!mounted) return;

      // Save সফল হলে সঙ্গে সঙ্গে screen update হবে।
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
      // Save শেষ হলে loading state বন্ধ করা।
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Logout করার আগে user-এর confirmation নেওয়া হবে।
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Out?'),
          content: const Text(
            'Are you sure you want to log out of ConnectHub?',
          ),
          actions: [
            // Cancel করলে dialog বন্ধ হবে।
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),

            // Confirm করলে logout হবে।
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

    // User Cancel করলে আর কোনো কাজ হবে না।
    if (shouldLogout != true) return;

    try {
      // Firebase account থেকে Sign Out।
      await FirebaseAuth.instance.signOut();

      // AuthGate-এর authStateChanges() নিজে থেকেই
      // Welcome Page দেখাবে। আলাদা navigation লাগবে না।
    } catch (error) {
      debugPrint('Logout error: $error');

      if (mounted) {
        _showMessage('Could not log out. Please try again.');
      }
    }
  }

  // ============================================================
  // SNACKBAR MESSAGE
  // Save সফল বা ব্যর্থ হলে ছোট message দেখাবে।
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // PROFILE UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Firebase থেকে তথ্য আসা পর্যন্ত loading indicator।
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Profile load না হলে error এবং retry button।
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined, size: 52),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
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

    // Nickname না থাকলে নাম থেকে একটি fallback handle দেখাবে।
    final handle = nickname.isNotEmpty
        ? '@$nickname'
        : '@${userName.toLowerCase().replaceAll(RegExp(r'\s+'), '')}';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: CustomScrollView(
          slivers: [
            // Profile information section।
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    
                     // Profile title ও Logout button একই row-তে দেখাবে।
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'My Profile',
                                            style: theme.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        // Logout button।
                                        TextButton.icon(
                                          onPressed: _logout,
                                          icon: const Icon(Icons.logout_rounded),
                                          label: const Text('Logout'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: colors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                    

                    const SizedBox(height: 28),

                    // Firebase-এ photoUrl থাকলে ছবি দেখাবে।
                    // না থাকলে default profile icon থাকবে।
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: colors.primary.withValues(alpha: 0.15),
                      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                          ? NetworkImage(photoUrl!)
                          : null,
                      child: photoUrl == null || photoUrl!.isEmpty
                          ? Icon(Icons.person, size: 65, color: colors.primary)
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Firestore-এ save হওয়া Profile Name।
                    Text(
                      userName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Custom nickname অথবা fallback handle।
                    Text(
                      handle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Firebase Authentication-এর email।
                    if (email.isNotEmpty)
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
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // নিজের Bio।
                    Text(
                      bio.isEmpty ? 'No bio added yet.' : bio,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 24),

                    // বর্তমান demo statistics।
                    Row(
                      children: [
                        Expanded(
                          child: _buildStat(
                            context,
                            'Posts',
                            '${posts.length}',
                          ),
                        ),
                        Expanded(
                          child: _buildStat(context, 'Followers', '128'),
                        ),
                        Expanded(child: _buildStat(context, 'Following', '96')),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Edit button: চাপলে dialog খুলবে।
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
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
                        label: Text(_isSaving ? 'Saving...' : 'Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Icon(Icons.grid_view_rounded, color: colors.primary),
                        const SizedBox(width: 10),
                        Text(
                          'My Posts',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Posts grid।
            // Responsive: বড় screen-এ 3 columns, অন্যথায় 2।
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = posts[index];
                  final color = post['color'] as Color;
                  final icon = post['icon'] as IconData;

                  return Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 42, color: color),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            post['title'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: posts.length),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 700
                      ? 3
                      : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // Statistics widget পুনরায় ব্যবহার করার জন্য helper method।
  Widget _buildStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EDIT PROFILE DIALOG
//
// গুরুত্বপূর্ণ:
// এই dialog-এর controllers এই widget-এর নিজের state-এ থাকে।
// Dialog বন্ধ হলে dispose() method সেগুলো dispose করে।
// তাই parent method-এ আগেভাগে controller dispose করতে হয় না।
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
  // Input validation-এর জন্য form key।
  final _formKey = GlobalKey<FormState>();

  // Dialog-এর input fields পরিচালনার controllers।
  late final TextEditingController _nameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();

    // আগের saved data input field-এ দেখাবে।
    _nameController = TextEditingController(text: widget.initialName);

    _nicknameController = TextEditingController(text: widget.initialNickname);

    _bioController = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    // Dialog widget dispose হওয়ার সময়ই controllers dispose হবে।
    _nameController.dispose();
    _nicknameController.dispose();
    _bioController.dispose();

    super.dispose();
  }

  // Input ঠিক থাকলে parent page-এ পরিবর্তিত data ফেরত পাঠানো।
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),

      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile name field।
                TextFormField(
                  controller: _nameController,
                  maxLength: 30,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Profile Name',
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
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

                // Nickname field: letters, numbers, underscore,
                // এবং dot গ্রহণ করবে।
                TextFormField(
                  controller: _nicknameController,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Nickname',
                    hintText: 'e.g. tanjim45',
                    prefixIcon: Icon(Icons.alternate_email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final nick = (value ?? '').trim().replaceFirst(
                      RegExp(r'^@+'),
                      '',
                    );

                    // Nickname ফাঁকা রাখাও যাবে।
                    if (nick.isEmpty) return null;

                    if (!RegExp(r'^[a-zA-Z0-9_.]{3,20}$').hasMatch(nick)) {
                      return 'Use 3–20 letters, numbers, . or _.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Bio field: সর্বোচ্চ 120 characters।
                TextFormField(
                  controller: _bioController,
                  maxLength: 120,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell people about yourself...',
                    prefixIcon: Icon(Icons.info_outline),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      actions: [
        // Cancel করলে dialog বন্ধ হবে, কোনো data save হবে না।
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),

        // Validate করে পরিবর্তিত data parent-এ ফেরত পাঠাবে।
        FilledButton.icon(
          onPressed: _saveProfile,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    );
  }
}
