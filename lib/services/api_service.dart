import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Update this with your backend URL
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Get stored token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Save token
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  // Save user data
  static Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user));
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return jsonDecode(userData) as Map<String, dynamic>;
    }
    return null;
  }

  // Make authenticated request
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle response
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'An error occurred');
    }
  }

  // ============ AUTH ============
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    final data = _handleResponse(response);
    if (data['token'] != null) {
      await _saveToken(data['token']);
      if (data['user'] != null) {
        await saveUserData(data['user']);
      }
    }
    return data;
  }

  // ============ USERS ============
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/search?q=$query'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/users/me'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // ============ CHATS ============
  static Future<Map<String, dynamic>> accessChat(String userId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/chats'),
      headers: headers,
      body: jsonEncode({'userId': userId}),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> fetchChats() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/chats'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // ============ MESSAGES ============
  static Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String content,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: headers,
      body: jsonEncode({
        'chatId': chatId,
        'content': content,
      }),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getMessages(String chatId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/messages/$chatId'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<void> markAsRead(String chatId) async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/messages/read'),
      headers: headers,
      body: jsonEncode({'chatId': chatId}),
    );
  }

  // ============ GROUPS ============
  static Future<Map<String, dynamic>> createGroup({
    required String name,
    required List<String> userIds,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'users': userIds,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> renameGroup({
    required String chatId,
    required String chatName,
  }) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/groups/rename'),
      headers: headers,
      body: jsonEncode({
        'chatId': chatId,
        'chatName': chatName,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> addToGroup({
    required String chatId,
    required String userId,
  }) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/groups/add'),
      headers: headers,
      body: jsonEncode({
        'chatId': chatId,
        'userId': userId,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> removeFromGroup({
    required String chatId,
    required String userId,
  }) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/groups/remove'),
      headers: headers,
      body: jsonEncode({
        'chatId': chatId,
        'userId': userId,
      }),
    );
    return _handleResponse(response);
  }

  // ============ FRIEND REQUESTS ============
  static Future<Map<String, dynamic>> sendFriendRequest(String receiverId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/friend-requests/send'),
      headers: headers,
      body: jsonEncode({'receiverId': receiverId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> acceptFriendRequest(String requestId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/friend-requests/accept'),
      headers: headers,
      body: jsonEncode({'requestId': requestId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> declineFriendRequest(String requestId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/friend-requests/decline'),
      headers: headers,
      body: jsonEncode({'requestId': requestId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getFriendRequests() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/friend-requests'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getFriends() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/friend-requests/friends'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<void> removeFriend(String friendId) async {
    final headers = await _getHeaders();
    await http.delete(
      Uri.parse('$baseUrl/friend-requests/remove'),
      headers: headers,
      body: jsonEncode({'friendId': friendId}),
    );
  }
}

