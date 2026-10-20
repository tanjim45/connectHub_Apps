import 'dart:typed_data';

import 'package:connecthub/features/user_info.dart';
import 'package:connecthub/models/user_model.dart';
import 'package:connecthub/models/post_model.dart';
import 'package:flutter/material.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final Uint8List? localImageBytes;
  final bool isLiked;
  final int likeCount;
  final List<String> comments;
  final TextEditingController commentController;
  final Future<UserModel> Function(int userId) getUser;
  final VoidCallback onLike;
  final VoidCallback onAddComment;

  const PostCard({
    super.key,
    required this.post,
    this.localImageBytes,
    required this.isLiked,
    required this.likeCount,
    required this.comments,
    required this.commentController,
    required this.getUser,
    required this.onLike,
    required this.onAddComment,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isSaved = false;
  final FocusNode _commentFocus = FocusNode();

  @override
  void dispose() {
    _commentFocus.dispose();
    super.dispose();
  }

  Widget _imagePlaceholder(ColorScheme colors, {bool withText = false}) {
    return Container(
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 44,
            color: colors.onSurfaceVariant,
          ),
          if (withText) ...[
            const SizedBox(height: 8),
            Text(
              'Image could not load',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImage(ColorScheme colors) {
    final hasLocal = widget.localImageBytes != null;
    final hasNetwork =
        widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty;

    if (!hasLocal && !hasNetwork) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1,
          child: hasLocal
              ? Image.memory(
                  widget.localImageBytes!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _imagePlaceholder(colors),
                )
              : Image.network(
                  widget.post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: colors.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      _imagePlaceholder(colors, withText: true),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: UserInfo(
                      userId: widget.post.userId,
                      getUser: widget.getUser,
                    ),
                  ),
                  IconButton(
                    tooltip: 'More options',
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        builder: (context) => SafeArea(
                          child: ListTile(
                            leading: const Icon(Icons.flag_outlined),
                            title: const Text('Report post'),
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                ],
              ),
            ),

            // Post image
            _buildImage(colors),

            // Title and caption
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
              child: Text(
                widget.post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: Text(
                widget.post.body.replaceAll('\n', ' '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: widget.isLiked ? 'Unlike' : 'Like',
                    onPressed: widget.onLike,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        widget.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border_rounded,
                        key: ValueKey(widget.isLiked),
                        color: widget.isLiked ? Colors.red : null,
                        size: 26,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.likeCount}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Comment',
                    onPressed: () => _commentFocus.requestFocus(),
                    icon: const Icon(Icons.mode_comment_outlined, size: 24),
                  ),
                  Text(
                    '${widget.comments.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Share',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share feature coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_outlined, size: 23),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#${widget.post.id}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: isSaved ? 'Unsave post' : 'Save post',
                    onPressed: () => setState(() => isSaved = !isSaved),
                    icon: Icon(
                      isSaved
                          ? Icons.bookmark
                          : Icons.bookmark_border_rounded,
                      size: 26,
                      color: isSaved ? colors.primary : null,
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: colors.outlineVariant,
            ),

            // Existing comments
            if (widget.comments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.comments.map((comment) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: colors.primaryContainer,
                            child: Icon(
                              Icons.person,
                              size: 16,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                  topLeft: Radius.circular(4),
                                ),
                              ),
                              child: Text(
                                comment,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Comment input
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.commentController,
                      focusNode: _commentFocus,
                      minLines: 1,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        filled: true,
                        fillColor: colors.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 1.2,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => widget.onAddComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send comment',
                    onPressed: widget.onAddComment,
                    icon: const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}