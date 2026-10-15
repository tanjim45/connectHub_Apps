
class UserModel {
  final int id;
  final String name;
  final String username;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
  });

  // JSON response convert UserModel object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
    );
  }
}