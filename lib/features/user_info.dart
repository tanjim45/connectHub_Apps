
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
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: colors.surfaceContainerHighest,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Loading profile...'),
            ],
          );
        }

        final user = snapshot.data!;
        final photoUrl =
            'https://i.pravatar.cc/150?img=${(user.id % 70) + 1}';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: colors.primaryContainer,
              child: ClipOval(
                child: Image.network(
                  photoUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;

                    return CircleAvatar(
                      radius: 25,
                      backgroundColor: colors.primaryContainer,
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
                    return CircleAvatar(
                      radius: 25,
                      backgroundColor: colors.primaryContainer,
                      child: Icon(
                        Icons.person,
                        color: colors.primary,
                        size: 28,
                      ),
                    );
                  },
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
                    ),
                  ),
                  const SizedBox(height: 3),
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
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: colors.primaryContainer,
          child: Icon(
            Icons.person,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 12),
        const Text('Unknown user'),
      ],
    );
  }
}
