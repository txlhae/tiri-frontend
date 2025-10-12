/// Cache Cleanup Service
/// Handles periodic cleanup of various app caches to maintain storage limits
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/api_client.dart';

/// Service for managing app cache sizes and cleanup
class CacheCleanupService {
  static const String _tag = 'CacheCleanupService';

  /// Target maximum cache sizes
  static const double maxApiCacheMB = 5.0;
  static const double maxTotalCacheMB = 10.0;

  /// Private constructor
  CacheCleanupService._();

  /// Perform comprehensive cache cleanup
  static Future<void> performCleanup({bool force = false}) async {
    try {
      if (kDebugMode) {
      }

      final sizeBefore = await getTotalCacheSizeMB();

      // Clean API cache
      await _cleanApiCache();

      // Clean temporary files (including any old image cache directories)
      await _cleanTempFiles();

      // Clean SharedPreferences if too large
      await _cleanSharedPreferences();

      final sizeAfter = await getTotalCacheSizeMB();
      final cleaned = sizeBefore - sizeAfter;

      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  /// Clean API cache if over limit
  static Future<void> _cleanApiCache() async {
    try {
      final cacheSize = await ApiClient.getCacheSizeMB();

      if (cacheSize > maxApiCacheMB) {
        await ApiClient.clearCache();
        if (kDebugMode) {
        }
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  /// Clean temporary files older than 1 hour (reduced from 24 hours)
  static Future<void> _cleanTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 1));

      // Also clean up any legacy image cache directories
      final legacyCacheDirs = [
        Directory('${tempDir.path}/image_cache'),
        Directory('${tempDir.path}/libCachedImageData'),
      ];

      for (final dir in legacyCacheDirs) {
        if (dir.existsSync()) {
          try {
            await dir.delete(recursive: true);
            if (kDebugMode) {
              print('Deleted legacy image cache: ${dir.path}');
            }
          } catch (e) {
            // Directory might be in use, skip
          }
        }
      }

      // Clean old temp files
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is File) {
          final lastModified = await entity.lastModified();
          if (lastModified.isBefore(cutoffTime)) {
            try {
              await entity.delete();
            } catch (e) {
              // File might be in use, skip
            }
          }
        }
      }

      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  /// Clean SharedPreferences if data is too large
  static Future<void> _cleanSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Calculate approximate size
      int totalSize = 0;
      for (final key in keys) {
        final value = prefs.get(key);
        if (value is String) {
          totalSize += value.length * 2; // Rough UTF-16 estimate
        }
      }

      final sizeMB = totalSize / (1024 * 1024);

      if (sizeMB > 5.0) { // If SharedPreferences > 5MB
        // Remove non-essential keys (keep auth data)
        final essentialKeys = {
          'access_token',
          'refresh_token',
          'user_data',
          'account_status',
          'next_step',
          'registration_stage'
        };

        for (final key in keys) {
          if (!essentialKeys.contains(key)) {
            await prefs.remove(key);
          }
        }

        if (kDebugMode) {
        }
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  /// Get total cache size in MB
  static Future<double> getTotalCacheSizeMB() async {
    try {
      double totalSize = 0.0;

      // API cache
      totalSize += await ApiClient.getCacheSizeMB();

      // Temp directory
      final tempDir = await getTemporaryDirectory();
      totalSize += await _getDirectorySizeMB(tempDir);

      return totalSize;
    } catch (e) {
      if (kDebugMode) {
      }
      return 0.0;
    }
  }

  /// Get directory size in MB
  static Future<double> _getDirectorySizeMB(Directory directory) async {
    try {
      if (!directory.existsSync()) return 0.0;

      int totalSize = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }

  /// Check if cleanup is needed based on size thresholds
  static Future<bool> isCleanupNeeded() async {
    final totalSize = await getTotalCacheSizeMB();
    return totalSize > maxTotalCacheMB;
  }

  /// Get cache status report
  static Future<Map<String, dynamic>> getCacheStatus() async {
    try {
      final apiCacheSize = await ApiClient.getCacheSizeMB();
      final totalSize = await getTotalCacheSizeMB();

      return {
        'total_cache_mb': totalSize,
        'api_cache_mb': apiCacheSize,
        'temp_cache_mb': totalSize - apiCacheSize,
        'cleanup_needed': totalSize > maxTotalCacheMB,
        'limits': {
          'max_api_cache_mb': maxApiCacheMB,
          'max_total_cache_mb': maxTotalCacheMB,
        },
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'cleanup_needed': true,
      };
    }
  }

  /// Schedule periodic cleanup (call this on app startup)
  static void schedulePeriodicCleanup() {
    // Run cleanup every hour if needed
    Stream.periodic(const Duration(hours: 1), (i) => i)
        .listen((_) async {
      if (await isCleanupNeeded()) {
        await performCleanup();
      }
    });
  }
}