import 'dart:typed_data';

import 'package:connecthub/models/post_model.dart';
import 'package:flutter/material.dart';
import 'package:connecthub/service/post_service.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostPage extends StatefulWidget {
  final ValueChanged<PostModel> onPostCreated;

  const CreatePostPage({
    super.key,
    required this.onPostCreated,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  bool _isPublishing = false;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isPickingImage = false;

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        if (!mounted) return;

        setState(() {
          _selectedImage = image;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ছবি নির্বাচন করা যায়নি। আবার চেষ্টা করো।'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _publishPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      final post = await PostService.createPost(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        userId: 1,
      );

      if (!mounted) return;

      final imageBytes = _selectedImageBytes ??
          (_selectedImage == null ? null : await _selectedImage!.readAsBytes());

      if (!mounted) return;

      final postWithImage = PostModel(
        userId: post.userId,
        id: post.id,
        title: post.title,
        body: post.body,
        imageUrl: post.imageUrl,
        thumbnailUrl: post.thumbnailUrl,
        localImageBytes: imageBytes,
      );

      widget.onPostCreated(postWithImage);

      _titleController.clear();
      _bodyController.clear();
      _formKey.currentState?.reset();

      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post created successfully! ID: ${post.id}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Post তৈরি করা যায়নি। Internet check করে আবার চেষ্টা করো।',
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _publishPost,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  InputDecoration _fieldDecoration(
    ColorScheme colors, {
    required String hint,
    Widget? prefix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      filled: true,
      fillColor: colors.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(Colors.transparent, 0),
      enabledBorder: border(Colors.transparent, 0),
      focusedBorder: border(colors.primary, 1.5),
      errorBorder: border(colors.error),
      focusedErrorBorder: border(colors.error, 1.5),
    );
  }

  Widget _sectionLabel(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    final colors = theme.colorScheme;

    if (_selectedImageBytes != null) {
      return Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(
                  _selectedImageBytes!,
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Change image',
                      onPressed: _isPickingImage ? null : _pickImage,
                      icon: const Icon(Icons.photo_library_outlined),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      tooltip: 'Remove image',
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _selectedImageBytes = null;
                        });
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _isPickingImage ? null : _pickImage,
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: _isPickingImage
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: colors.onPrimaryContainer,
                        ),
                      )
                    : Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 28,
                        color: colors.onPrimaryContainer,
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                _isPickingImage ? 'Opening Gallery...' : 'Tap to choose an image',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Card(
            elevation: 0,
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colors.primary, colors.tertiary],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            size: 28,
                            color: colors.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create a Post',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Share your thoughts with ConnectHub',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    _sectionLabel(theme, Icons.image_outlined, 'Post Image'),
                    const SizedBox(height: 12),
                    _buildImagePicker(theme),

                    const SizedBox(height: 24),

                    _sectionLabel(theme, Icons.title_rounded, 'Post Title'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _fieldDecoration(
                        colors,
                        hint: 'What is your post about?',
                        prefix: const Icon(Icons.short_text_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Post title লিখো';
                        }
                        if (value.trim().length < 3) {
                          return 'Title কমপক্ষে 3 characters হতে হবে';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    _sectionLabel(
                      theme,
                      Icons.notes_rounded,
                      'Post Description',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bodyController,
                      minLines: 6,
                      maxLines: 10,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _fieldDecoration(
                        colors,
                        hint: 'Write something you want to share...',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Post description লিখো';
                        }
                        if (value.trim().length < 5) {
                          return 'Description কমপক্ষে 5 characters হতে হবে';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: colors.onSecondaryContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'তোমার title ও description API-তে পাঠানো হবে।',
                              style: TextStyle(
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _isPublishing ? null : _publishPost,
                        icon: _isPublishing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isPublishing ? 'Publishing...' : 'Publish Post',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}