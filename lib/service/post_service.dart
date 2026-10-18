
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:connecthub/models/post_model.dart';
import 'package:connecthub/models/user_model.dart';

class PostService {
  static const String postsUrl =
      'https://jsonplaceholder.typicode.com/posts';

  static const String usersUrl =
      'https://jsonplaceholder.typicode.com/users';

  static const String photosUrl =
      'https://jsonplaceholder.typicode.com/photos';

  // Fetch posts with pagination.
  static Future<List<PostModel>> fetchPosts({
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse(postsUrl).replace(
      queryParameters: {
        '_page': page.toString(),
        '_limit': limit.toString(),
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData =
          jsonDecode(response.body) as List<dynamic>;

      return jsonData.map((item) {
        return PostModel.fromJson(
          item as Map<String, dynamic>,
        );
      }).toList();
    }

    throw Exception(
      'Posts load failed: ${response.statusCode}',
    );
  }

  // Fetch a user profile.
  static Future<UserModel> fetchUser(int userId) async {
    final response = await http.get(
      Uri.parse('$usersUrl/$userId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData =
          jsonDecode(response.body) as Map<String, dynamic>;

      return UserModel.fromJson(jsonData);
    }

    throw Exception(
      'User load failed: ${response.statusCode}',
    );
  }

  // Fetch photo data from API.
  static Future<List<Map<String, dynamic>>> fetchPhotos({
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse(photosUrl).replace(
      queryParameters: {
        '_page': page.toString(),
        '_limit': limit.toString(),
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData =
          jsonDecode(response.body) as List<dynamic>;

      return jsonData.map((item) {
        return item as Map<String, dynamic>;
      }).toList();
    }

    throw Exception(
      'Photos load failed: ${response.statusCode}',
    );
  }

  // Create a new post using API.
  static Future<PostModel> createPost({
    required String title,
    required String body,
    int userId = 1,
  }) async {
    final response = await http.post(
      Uri.parse(postsUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'title': title,
        'body': body,
        'userId': userId,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData =
          jsonDecode(response.body) as Map<String, dynamic>;

      return PostModel.fromJson(jsonData);
    }

    throw Exception(
      'Post creation failed: ${response.statusCode}',
    );
  }
}
