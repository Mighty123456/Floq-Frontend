import 'package:hive_flutter/hive_flutter.dart';
import '../../features/feed/domain/entities/post_entity.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  late Box _feedBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _feedBox = await Hive.openBox('feed_cache');
  }

  Future<void> cacheFeed(List<PostEntity> posts) async {
    // We only cache the first page for offline viewing
    final data = posts.map((p) => p.toJson()).toList();
    await _feedBox.put('posts', data);
  }

  List<dynamic> getCachedFeed() {
    return _feedBox.get('posts', defaultValue: []) as List<dynamic>;
  }

  Future<void> clearCache() async {
    await _feedBox.clear();
  }
}
