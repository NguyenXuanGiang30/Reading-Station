/// Cache Service - API response caching for offline support
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cache entry with expiration
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration expiresIn;
  
  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiresIn,
  });
  
  bool get isExpired => DateTime.now().isAfter(timestamp.add(expiresIn));
  
  Duration get remainingTime {
    final expiry = timestamp.add(expiresIn);
    return expiry.difference(DateTime.now());
  }
}

/// Cache service for API responses
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Map<String, CacheEntry<dynamic>> _memoryCache = {};
  
  static const String _cachePrefix = 'cache_';
  static const String _cacheIndexKey = 'cache_index';
  
  // Default cache duration
  static const Duration defaultCacheDuration = Duration(minutes: 5);
  static const Duration longCacheDuration = Duration(hours: 24);
  
  CacheService._internal();
  
  /// Initialize cache service
  Future<void> init() async {
    // Clean expired entries on startup
    await cleanExpiredCache();
  }
  
  /// Get cached data
  Future<T?> get<T>(String key) async {
    // Check memory cache first
    final memEntry = _memoryCache[key];
    if (memEntry != null && !memEntry.isExpired) {
      return memEntry.data as T;
    }
    
    // Check persistent storage
    try {
      final jsonStr = await _storage.read(key: '$_cachePrefix$key');
      if (jsonStr == null) return null;
      
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final timestamp = DateTime.parse(json['timestamp']);
      final expiresIn = Duration(milliseconds: json['expiresInMs']);
      final data = json['data'];
      
      final entry = CacheEntry(
        data: data,
        timestamp: timestamp,
        expiresIn: expiresIn,
      );
      
      if (entry.isExpired) {
        await remove(key);
        return null;
      }
      
      // Store in memory cache
      _memoryCache[key] = entry;
      
      return data as T;
    } catch (e) {
      return null;
    }
  }
  
  /// Set cached data
  Future<void> set<T>(
    String key,
    T data, {
    Duration expiresIn = defaultCacheDuration,
  }) async {
    final entry = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      expiresIn: expiresIn,
    );
    
    // Store in memory cache
    _memoryCache[key] = entry;
    
    // Store in persistent storage
    try {
      final json = {
        'timestamp': entry.timestamp.toIso8601String(),
        'expiresInMs': entry.expiresIn.inMilliseconds,
        'data': data,
      };
      await _storage.write(
        key: '$_cachePrefix$key',
        value: jsonEncode(json),
      );
      
      // Update cache index
      await _updateCacheIndex(key);
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }
  
  /// Remove cached data
  Future<void> remove(String key) async {
    // Remove from memory
    _memoryCache.remove(key);
    
    // Remove from storage
    try {
      await _storage.delete(key: '$_cachePrefix$key');
      await _removeFromCacheIndex(key);
    } catch (e) {
      debugPrint('Cache remove error: $e');
    }
  }
  
  /// Clear all cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    
    try {
      final index = await _getCacheIndex();
      for (final key in index) {
        await _storage.delete(key: '$_cachePrefix$key');
      }
      await _storage.delete(key: _cacheIndexKey);
    } catch (e) {
      debugPrint('Cache clear error: $e');
    }
  }
  
  /// Clean expired cache entries
  Future<void> cleanExpiredCache() async {
    try {
      final index = await _getCacheIndex();
      final expiredKeys = <String>[];
      
      for (final key in index) {
        final memEntry = _memoryCache[key];
        if (memEntry != null && memEntry.isExpired) {
          expiredKeys.add(key);
          _memoryCache.remove(key);
        }
      }
      
      for (final key in expiredKeys) {
        await _storage.delete(key: '$_cachePrefix$key');
        await _removeFromCacheIndex(key);
      }
    } catch (e) {
      debugPrint('Cache clean error: $e');
    }
  }
  
  /// Get cache size (approximate)
  Future<int> getCacheSize() async {
    try {
      final index = await _getCacheIndex();
      return index.length;
    } catch (e) {
      return 0;
    }
  }
  
  /// Check if key is cached
  Future<bool> hasKey(String key) async {
    // Check memory first
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key];
      if (entry != null && !entry.isExpired) {
        return true;
      }
    }
    
    // Check storage
    try {
      final jsonStr = await _storage.read(key: '$_cachePrefix$key');
      if (jsonStr == null) return false;
      
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final timestamp = DateTime.parse(json['timestamp']);
      final expiresIn = Duration(milliseconds: json['expiresInMs']);
      
      return DateTime.now().isBefore(timestamp.add(expiresIn));
    } catch (e) {
      return false;
    }
  }
  
  // Helper methods
  Future<Set<String>> _getCacheIndex() async {
    try {
      final indexStr = await _storage.read(key: _cacheIndexKey);
      if (indexStr == null) return {};
      return Set<String>.from(jsonDecode(indexStr) as List);
    } catch (e) {
      return {};
    }
  }
  
  Future<void> _updateCacheIndex(String key) async {
    try {
      final index = await _getCacheIndex();
      index.add(key);
      await _storage.write(key: _cacheIndexKey, value: jsonEncode(index.toList()));
    } catch (e) {
      debugPrint('Cache index update error: $e');
    }
  }
  
  Future<void> _removeFromCacheIndex(String key) async {
    try {
      final index = await _getCacheIndex();
      index.remove(key);
      await _storage.write(key: _cacheIndexKey, value: jsonEncode(index.toList()));
    } catch (e) {
      debugPrint('Cache index remove error: $e');
    }
  }
}

/// Extension for easy caching in services
extension CacheableFuture<T> on Future<T> {
  /// Cache the result of a future
  Future<T> cached(CacheService cache, String key, {Duration? expiresIn}) async {
    // Try to get from cache first
    final cached = await cache.get<T>(key);
    if (cached != null) {
      return cached;
    }
    
    // Get fresh data
    final data = await this;
    
    // Cache the result
    await cache.set(key, data, expiresIn: expiresIn ?? CacheService.defaultCacheDuration);
    
    return data;
  }
}
