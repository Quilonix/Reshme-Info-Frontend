import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const Duration defaultTTL = Duration(minutes: 15);

  /// Retrieve cached data if valid, otherwise return null
  static Future<T?> get<T>({
    required String key,
    Duration ttl = defaultTTL,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cache_$key');
      if (raw == null) return null;

      final Map<String, dynamic> wrapper = jsonDecode(raw);
      final timestamp = wrapper['timestamp'] as int?;
      if (timestamp == null) return null;

      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      if (now.difference(cachedAt) > ttl) {
        return null; // Expired
      }

      return wrapper['data'] as T?;
    } catch (e) {
      debugPrint('Cache get notice ($key): $e');
      return null;
    }
  }

  /// Store data in local cache with current timestamp
  static Future<void> set({
    required String key,
    required dynamic data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wrapper = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };
      await prefs.setString('cache_$key', jsonEncode(wrapper));
    } catch (e) {
      debugPrint('Cache set notice ($key): $e');
    }
  }

  /// Clear specific cache key or all keys
  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cache_$key');
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
