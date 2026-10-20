
class ChatUser {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String nickname;
  final String bio;

  const ChatUser({
    required this.uid,
    required this.name,
    this.email = '',
    this.photoUrl = '',
    this.nickname = '',
    this.bio = '',
  });

  factory ChatUser.fromMap(
    String uid,
    Map<String, dynamic> data,
  ) {
    return ChatUser(
      uid: uid,
      name: (data['profileName'] as String?) ?? 'Unknown user',
      email: (data['email'] as String?) ?? '',
      photoUrl: (data['photoUrl'] as String?) ?? '',
      nickname: (data['nickname'] as String?) ?? '',
      bio: (data['bio'] as String?) ?? '',
    );
  }
}
