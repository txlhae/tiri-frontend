/// App Cache Manager
/// Centralized service for initializing and managing all app caches
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'api/api_client.dart';
import 'cache_cleanup_service.dart';
import 'image_cache_service.dart';
import 'auth_storage.dart';

/// Centralized cache management service
class AppCacheManager extends GetxService {
  static const String _tag = 'AppCacheManager';

  /// Target storage limits
  static const CacheTargets targets = CacheTargets(
    appSizeMB: 20.0,        // Target: <20MB
    dataSizeMB: 50.0,       // Target: <50MB
    cacheSizeMB: 5.0,       // Target: <5MB (minimal)
  );

  /// Initialize all cache systems with strict limits
  @override
  Future<void> onInit() async {
    super.onInit();
    await initializeCacheSystems();
  }

  /// Initialize all cache systems
  static Future<void> initializeCacheSystems() async {
    try {
      if (kDebugMode) {
      }

      // 1. Initialize API client with minimal cache
      ApiClient.initialize(
        enableCache: !kReleaseMode, // Disable cache in release mode
        maxCacheSizeMB: 2, // Very small cache
      );

      // 2. Initialize image cache with strict limits
      await ImageCacheService.initialize();

      // 3. Schedule periodic cleanup
      CacheCleanupService.schedulePeriodicCleanup();

      // 4. Perform initial cleanup
      await performInitialCleanup();

      if (kDebugMode) {
        await logCacheStatus();
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  /// Perform initial cleanup to meet target sizes
  static Future<void> performInitialCleanup() async {
    try {
      if (kDebugMode) {
      }

      // Get current sizes
      final status = await getCacheStatus();

      if (status['cleanup_needed'] == true) {
        await CacheCleanupService.performCleanup(force: true);

        if (kDebugMode) {
          await logCacheStatus();
        }
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  /// Get comprehensive cache status
  static Future<Map<String, dynamic>> getCacheStatus() async {
    try {
      final cleanupStatus = await CacheCleanupService.getCacheStatus();
      final imageCacheSize = await ImageCacheService.getImageCacheSizeMB();
      final authStorageSize = await AuthStorage.getStorageSizeKB();

      return {
        ...cleanupStatus,
        'image_cache_mb': imageCacheSize,
        'auth_storage_kb': authStorageSize,
        'targets': {
          'app_mb': targets.appSizeMB,
          'data_mb': targets.dataSizeMB,
          'cache_mb': targets.cacheSizeMB,
        },
        'within_limits': {
          'cache': cleanupStatus['total_cache_mb'] <= targets.cacheSizeMB,
          'image': imageCacheSize <= ImageCacheService.maxCacheSizeMB,
          'auth': authStorageSize <= AuthStorage.maxStorageSizeKB,
        },
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'cleanup_needed': true,
      };
    }
  }

  /// Log current cache status
  static Future<void> logCacheStatus() async {
    try {
      final status = await getCacheStatus();

      if (kDebugMode) {

        final withinLimits = status['within_limits'] as Map<String, dynamic>? ?? {};
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  /// Perform aggressive cleanup to meet targets
  static Future<void> aggressiveCleanup() async {
    try {
      if (kDebugMode) {
      }

      // 1. Clear all caches
      await ApiClient.clearCache();
      await ImageCacheService.clearImageCache();
      await AuthStorage.performCleanup();

      // 2. Comprehensive cache cleanup
      await CacheCleanupService.performCleanup(force: true);

      if (kDebugMode) {
        await logCacheStatus();
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  /// Check if any cache exceeds limits
  static Future<bool> isAnyLimitExceeded() async {
    try {
      final status = await getCacheStatus();
      final withinLimits = status['within_limits'] as Map<String, dynamic>? ?? {};

      return !withinLimits.values.every((v) => v == true);
    } catch (e) {
      return true; // Assume limits exceeded if we can't check
    }
  }

  /// Get memory usage statistics
  static Future<Map<String, dynamic>> getMemoryStats() async {
    try {
      return {
        'image_cache_count': PaintingBinding.instance.imageCache.currentSize,
        'image_cache_bytes': PaintingBinding.instance.imageCache.currentSizeBytes,
        'image_cache_limit_count': PaintingBinding.instance.imageCache.maximumSize,
        'image_cache_limit_bytes': PaintingBinding.instance.imageCache.maximumSizeBytes,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Emergency cleanup when storage is critically low
  static Future<void> emergencyCleanup() async {
    try {
      if (kDebugMode) {
      }

      // Clear everything aggressively
      await aggressiveCleanup();

      // Additional emergency measures - clear Flutter's image cache
      try {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      } catch (e) {
        if (kDebugMode) {
        }
      }

      if (kDebugMode) {
        await logCacheStatus();
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }
}

/// Cache target sizes
class CacheTargets {
  final double appSizeMB;
  final double dataSizeMB;
  final double cacheSizeMB;

  const CacheTargets({
    required this.appSizeMB,
    required this.dataSizeMB,
    required this.cacheSizeMB,
  });
}