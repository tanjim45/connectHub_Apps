
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
            child: Row(
              children: [
                UserInfo(
                  userId: widget.post.userId,
                  getUser: widget.getUser,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'More options',
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
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

          // Post image from API
          if (widget.post.imageUrl != null &&
              widget.post.imageUrl!.isNotEmpty)
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
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
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colors.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined, size: 44),
                        SizedBox(height: 8),
                        Text('Image could not load'),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Post title and caption
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              widget.post.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              widget.post.body.replaceAll('\n', ' '),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),

          // Like, comment and save actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: widget.isLiked ? 'Unlike' : 'Like',
                  onPressed: widget.onLike,
                  icon: Icon(
                    widget.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border_rounded,
                    color: widget.isLiked ? Colors.red : null,
                    size: 27,
                  ),
                ),
                IconButton(
                  tooltip: 'Comment',
                  onPressed: () {
                    FocusScope.of(context).requestFocus(
                      FocusNode(),
                    );
                  },
                  icon: const Icon(
                    Icons.mode_comment_outlined,
                    size: 25,
                  ),
                ),
                IconButton(
                  tooltip: 'Share',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share feature coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_outlined, size: 24),
                ),
                const Spacer(),
                IconButton(
                  tooltip: isSaved ? 'Unsave post' : 'Save post',
                  onPressed: () {
                    setState(() => isSaved = !isSaved);
                  },
                  icon: Icon(
                    isSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border_rounded,
                    size: 27,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${widget.likeCount} likes',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.comments.length} comments',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  'Post #${widget.post.id}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Comment input
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.commentController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      filled: true,
                      fillColor: colors.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => widget.onAddComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Send comment',
                  onPressed: widget.onAddComment,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),

          if (widget.comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.comments.map((comment) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          child: Icon(Icons.person, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(comment)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
