
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class GitHubSync {
  final _secureStorage = const FlutterSecureStorage();
  final String _tokenKey = 'github_token';
  final String _usernameKey = 'github_username';
  final String _repoKey = 'github_repo';

  Future<bool> isAuthenticated() async {
    return await _secureStorage.containsKey(key: _tokenKey);
  }

  Future<void> saveCredentials(String token, String username, String repo) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _usernameKey, value: username);
    await _secureStorage.write(key: _repoKey, value: repo);
  }

  Future<Map<String, String?>> getCredentials() async {
    return {
      'token': await _secureStorage.read(key: _tokenKey),
      'username': await _secureStorage.read(key: _usernameKey),
      'repo': await _secureStorage.read(key: _repoKey),
    };
  }

  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _repoKey);
  }

  Future<void> syncData(String data) async {
    try {
      final credentials = await getCredentials();
      final token = credentials['token'];
      final username = credentials['username'];
      final repo = credentials['repo'];

      if (token == null || username == null || repo == null) {
        throw Exception('GitHub credentials not set');
      }

      final fileName = 'credit_card_data.json';
      final content = base64Encode(utf8.encode(data));
      final message = 'Update credit card data ${DateTime.now().toIso8601String()}';

      // Get current file SHA (if exists)
      String? sha;
      final getShaResponse = await http.get(
        Uri.parse('https://api.github.com/repos/$username/$repo/contents/$fileName'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (getShaResponse.statusCode == 200) {
        final fileInfo = jsonDecode(getShaResponse.body);
        sha = fileInfo['sha'];
      }

      // Create or update file
      final Map<String, dynamic> body = {
        'message': message,
        'content': content,
      };

      if (sha != null) {
        body['sha'] = sha;
      }

      final response = await http.put(
        Uri.parse('https://api.github.com/repos/$username/$repo/contents/$fileName'),
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/vnd.github.v3+json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to sync data: ${response.body}');
      }
    } catch (e) {
      print('Error syncing to GitHub: $e');
    }
  }

  Future<String?> loadDataFromGitHub() async {
    try {
      final credentials = await getCredentials();
      final token = credentials['token'];
      final username = credentials['username'];
      final repo = credentials['repo'];

      if (token == null || username == null || repo == null) {
        return null;
      }

      final fileName = 'credit_card_data.json';
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$username/$repo/contents/$fileName'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final fileInfo = jsonDecode(response.body);
        final content = fileInfo['content'];
        final encoding = fileInfo['encoding'];
        
        if (encoding == 'base64') {
          return utf8.decode(base64Decode(content.replaceAll('\n', '')));
        }
      }
      return null;
    } catch (e) {
      print('Error loading data from GitHub: $e');
      return null;
    }
  }
}
