import 'dart:convert';
import 'package:http/http.dart' as http;

class GiphyService {
  final String _apiKey = 'Pv8JaQ71M26W1xodPIX9EXzYlWovULQK';
  final String _baseUrl = 'https://api.giphy.com/v1';

  Future<List<String>> getTrendingGifs({int limit = 20}) async {
    final response = await http.get(Uri.parse('$_baseUrl/gifs/trending?api_key=$_apiKey&limit=$limit&rating=g'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((gif) => gif['images']['fixed_height']['url'] as String).toList();
    }
    return [];
  }

  Future<List<String>> searchGifs(String query, {int limit = 20}) async {
    if (query.isEmpty) return getTrendingGifs(limit: limit);
    final response = await http.get(Uri.parse('$_baseUrl/gifs/search?api_key=$_apiKey&q=$query&limit=$limit&rating=g'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((gif) => gif['images']['fixed_height']['url'] as String).toList();
    }
    return [];
  }

  Future<List<String>> getTrendingStickers({int limit = 20}) async {
    final response = await http.get(Uri.parse('$_baseUrl/stickers/trending?api_key=$_apiKey&limit=$limit&rating=g'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((gif) => gif['images']['fixed_height']['url'] as String).toList();
    }
    return [];
  }

  Future<List<String>> searchStickers(String query, {int limit = 20}) async {
    if (query.isEmpty) return getTrendingStickers(limit: limit);
    final response = await http.get(Uri.parse('$_baseUrl/stickers/search?api_key=$_apiKey&q=$query&limit=$limit&rating=g'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((gif) => gif['images']['fixed_height']['url'] as String).toList();
    }
    return [];
  }
}
