
import 'dart:typed_data';

class PostModel {
  final int userId;
  final int id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? thumbnailUrl;

  final Uint8List? localImageBytes;

  const PostModel({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.thumbnailUrl,
    this.localImageBytes,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      userId: json['userId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['url'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}
