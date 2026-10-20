import 'package:flutter/material.dart';
import 'package:connecthub/models/user_model.dart';

class UserInfo extends StatelessWidget {
  final int userId;
  final Future<UserModel> Function(int) getUser;

  const UserInfo({
    super.key,
    required this.userId,
    required this.getUser,
  });

  // Gradient ring around the avatar.
  Widget _ring(ColorScheme colors, Widget child) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.tertiary],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surface,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FutureBuilder<UserModel>(
      future: getUser(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildFallback(colors);
        }

        if (!snapshot.hasData) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: colors.surfaceContainerHighest,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading profile...',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          );
        }

        final user = snapshot.data!;
        final photoUrl = 'https://i.pravatar.cc/150?img=${(user.id % 70) + 1}';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ring(
              colors,
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.primaryContainer,
                child: ClipOval(
                  child: Image.network(
                    photoUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;

                      return Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        color: colors.primary,
                        size: 26,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFallback(ColorScheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: colors.primaryContainer,
          child: Icon(Icons.person, color: colors.primary),
        ),
        const SizedBox(width: 12),
        const Text(
          'Unknown user',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}