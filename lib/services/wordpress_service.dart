import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WordPressPost {
  final int id;
  final String title;
  final String content;
  final String excerpt;
  final String date;
  final String link;
  final String? featuredImageUrl;

  WordPressPost({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.date,
    required this.link,
    this.featuredImageUrl,
  });

  factory WordPressPost.fromJson(Map<String, dynamic> json) {
    return WordPressPost(
      id: json['id'],
      title: json['title']['rendered'] ?? '',
      content: json['content']['rendered'] ?? '',
      excerpt: json['excerpt']['rendered'] ?? '',
      date: json['date'] ?? '',
      link: json['link'] ?? '',
      featuredImageUrl:
          json['_embedded']?['wp:featuredmedia']?[0]?['source_url'],
    );
  }
}

class WordPressService {
  // Development mode: Set to true for testing without app key
  // Production mode: Set to false and configure .env file
  static const bool isDevelopmentMode = true;

  // Load from environment variables for security (production)
  // Or use hardcoded values for development testing
  static String get baseUrl {
    if (isDevelopmentMode) {
      // TODO: Replace with your WordPress site URL for testing
      return 'https://agrodana-futures.com';
    }
    return dotenv.env['WORDPRESS_URL'] ?? 'https://agrodana-futures.com';
  }

  static String get apiEndpoint => '$baseUrl/wp-json/wp/v2';

  static String get fcmAppKey {
    if (isDevelopmentMode) {
      // For development: Leave empty to use WordPress public mode
      // Your WordPress plugin allows public access if no app key is set
      return '';
    }
    return dotenv.env['FCM_APP_KEY'] ?? '';
  }

  // Validate configuration
  static bool get isConfigured {
    if (isDevelopmentMode) {
      return baseUrl != 'https://your-wordpress-site.com';
    }
    return baseUrl != 'https://your-wordpress-site.com' && fcmAppKey.isNotEmpty;
  }

  /// Fetch latest posts from WordPress
  Future<List<WordPressPost>> fetchPosts({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$apiEndpoint/posts?page=$page&per_page=$perPage&_embed'),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((post) => WordPressPost.fromJson(post)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      throw Exception('Failed to fetch posts: $e');
    }
  }

  /// Fetch a single post by ID
  Future<WordPressPost> fetchPostById(int postId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiEndpoint/posts/$postId?_embed'),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = json.decode(response.body);
        return WordPressPost.fromJson(jsonData);
      } else {
        throw Exception('Failed to load post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching post: $e');
      throw Exception('Failed to fetch post: $e');
    }
  }

  /// Register FCM token with WordPress backend
  /// This requires a custom WordPress endpoint (see wordpress_plugin.php)
  Future<bool> registerFCMToken(String fcmToken) async {
    try {
      // Build request body
      final Map<String, dynamic> requestBody = {
        'fcm_token': fcmToken,
        'device_type': 'flutter',
      };

      // Only include app_key if not in development mode or if app_key is set
      if (!isDevelopmentMode && fcmAppKey.isNotEmpty) {
        requestBody['app_key'] = fcmAppKey;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/wp-json/fcm/v1/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token registered successfully');
        if (isDevelopmentMode) {
          print('ℹ️  Development mode: Using public API access');
        }
        return true;
      } else if (response.statusCode == 401) {
        print('❌ Failed to register FCM token: Unauthorized (check app_key)');
        print('Response: ${response.body}');
        return false;
      } else if (response.statusCode == 429) {
        print(
          '⚠️  Failed to register FCM token: Rate limit exceeded (wait 60s)',
        );
        print('Response: ${response.body}');
        return false;
      } else {
        print('❌ Failed to register FCM token: ${response.statusCode}');
        print('Response body: ${response.body}');

        // Try to parse error message from response
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            print('Error message: ${errorData['message']}');
          }
          if (errorData['data'] != null) {
            print('Error data: ${errorData['data']}');
          }
        } catch (e) {
          // Response is not JSON, already printed above
        }
        return false;
      }
    } catch (e) {
      print('❌ Error registering FCM token: $e');
      return false;
    }
  }

  /// Unregister FCM token from WordPress backend
  Future<bool> unregisterFCMToken(String fcmToken) async {
    try {
      // Build request body
      final Map<String, dynamic> requestBody = {'fcm_token': fcmToken};

      // Only include app_key if not in development mode or if app_key is set
      if (!isDevelopmentMode && fcmAppKey.isNotEmpty) {
        requestBody['app_key'] = fcmAppKey;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/wp-json/fcm/v1/unregister'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token unregistered successfully');
        return true;
      } else if (response.statusCode == 401) {
        print('❌ Failed to unregister FCM token: Unauthorized (check app_key)');
        return false;
      } else if (response.statusCode == 429) {
        print(
          '⚠️  Failed to unregister FCM token: Rate limit exceeded (wait 60s)',
        );
        return false;
      } else {
        print('❌ Failed to unregister FCM token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error unregistering FCM token: $e');
      return false;
    }
  }
}
