
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
    return FutureBuilder<UserModel>(
      future: getUser(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Row(
            children: [
              CircleAvatar(
                child: Icon(Icons.person),
              ),
              SizedBox(width: 12),
              Text('Unknown user'),
            ],
          );
        }

        if (!snapshot.hasData) {
          return const Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text('Loading profile...'),
            ],
          );
        }

        final user = snapshot.data!;

        return Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: const Color(0xFFDCEBFF),
              child: Text(
                user.name.isNotEmpty
                    ? user.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF1769C2),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.public,
              size: 19,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ],
        );
      },
    );
  }
}
