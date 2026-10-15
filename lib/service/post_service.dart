import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class PostService {
  static const String url =
      'https://jsonplaceholder.typicode.com/posts';

  static Future<List<PostModel>> fetchPosts() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData =
          jsonDecode(response.body) as List<dynamic>;

      return jsonData.map((post) {
        return PostModel.fromJson(
          post as Map<String, dynamic>,
        );
      }).toList();
    } else {
      throw Exception(
        'Posts load failed: ${response.statusCode}',
      );
    }
  }
}
