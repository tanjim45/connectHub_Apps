
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connecthub/models/post_model.dart';
import 'package:connecthub/models/user_model.dart';

class PostService {
  static const String postsUrl =
      'https://jsonplaceholder.typicode.com/posts';

  static const String usersUrl =
      'https://jsonplaceholder.typicode.com/users';

  // API  page posts 
  
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

  // User ID user-username ।
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
}
