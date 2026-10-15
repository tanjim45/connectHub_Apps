import 'dart:convert';
import 'package:http/http.dart' as http;

class PostService {
  static const String url =
      'https://jsonplaceholder.typicode.com/posts';

  static Future<List<dynamic>> fetchPosts() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception(
        'Posts load failed: ${response.statusCode}',
      );
    }
  }
}