/// Image Cache Service
/// Manages cached network images with strict size limits
library;

import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing image cache with size limits
class ImageCacheService {
  static const String _tag = 'ImageCacheService';

  /// Maximum image cache size in MB
  static const double maxCacheSizeMB = 8.0;

  /// Maximum cache age in hours
  static const int maxCacheAgeHours = 24;

  /// Singleton instance
  static ImageCacheService? _instance;

  /// Private constructor
  ImageCacheService._();

  /// Get singleton instance
  static ImageCacheService get instance {
    _instance ??= ImageCacheService._();
    return _instance!;
  }

  /// Initialize image cache with size limits
  static Future<void> initialize() async {
    try {
      // Set global image cache size limits
      PaintingBinding.instance.imageCache.maximumSize = 50; // Max 50 images in memory
      PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB memory limit

      if (kDebugMode) {
        log('🖼️ [$_tag] Image cache initialized with size limits');
      }
    } catch (e) {
      if (kDebugMode) {
        log('❌ [$_tag] Failed to initialize: $e');
      }
    }
  }

  /// Get optimized CachedNetworkImage widget with size limits
  static Widget getCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Map<String, String>? httpHeaders,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: httpHeaders,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 800, // Limit disk cache image width
      maxHeightDiskCache: 800, // Limit disk cache image height
      placeholder: placeholder != null
          ? (context, url) => placeholder
          : (context, url) => Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(Icons.image, color: Colors.grey),
            ),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget
          : (context, url, error) => Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(Icons.error, color: Colors.red),
            ),
      cacheManager: CustomCacheManager.instance,
    );
  }

  /// Clear all image cache
  static Future<void> clearImageCache() async {
    try {
      // Clear memory cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Clear disk cache
      await CustomCacheManager.instance.emptyCache();

      if (kDebugMode) {
        log('🗑️ [$_tag] Image cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        log('❌ [$_tag] Failed to clear cache: $e');
      }
    }
  }

  /// Get current image cache size in MB
  static Future<double> getImageCacheSizeMB() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/libCachedImageData');

      if (!cacheDir.existsSync()) return 0.0;

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize / (1024 * 1024);
    } catch (e) {
      if (kDebugMode) {
        log('❌ [$_tag] Failed to get cache size: $e');
      }
      return 0.0;
    }
  }

  /// Check if cache cleanup is needed
  static Future<bool> isCleanupNeeded() async {
    final cacheSize = await getImageCacheSizeMB();
    return cacheSize > maxCacheSizeMB;
  }

  /// Perform cache cleanup if needed
  static Future<void> cleanupIfNeeded() async {
    if (await isCleanupNeeded()) {
      await clearImageCache();
      if (kDebugMode) {
        log('🧹 [$_tag] Cache cleanup performed');
      }
    }
  }
}

/// Custom cache manager with strict size and time limits
class CustomCacheManager extends CacheManager {
  static const String key = 'tiri_image_cache';

  static CustomCacheManager? _instance;

  /// Get singleton instance
  static CustomCacheManager get instance {
    _instance ??= CustomCacheManager._();
    return _instance!;
  }

  /// Private constructor
  CustomCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(hours: ImageCacheService.maxCacheAgeHours),
            maxNrOfCacheObjects: 200, // Max 200 cached images
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );

  /// Enforce maximum cache size by removing oldest files
  Future<void> _enforceMaxCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/libCachedImageData');

      if (!cacheDir.existsSync()) return;

      // Get all cache files with their stats
      final files = <FileSystemEntity>[];
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          files.add(entity);
        }
      }

      // Sort by last accessed time (oldest first)
      files.sort((a, b) {
        final aFile = a as File;
        final bFile = b as File;
        return aFile.lastModifiedSync().compareTo(bFile.lastModifiedSync());
      });

      // Calculate total size
      int totalSize = 0;
      for (final file in files) {
        totalSize += await (file as File).length();
      }

      final maxSizeBytes = (ImageCacheService.maxCacheSizeMB * 1024 * 1024).toInt();

      // Remove oldest files if over limit
      int currentSize = totalSize;
      final filesToRemove = <File>[];

      for (final file in files) {
        if (currentSize <= maxSizeBytes) break;

        final fileSize = await (file as File).length();
        filesToRemove.add(file);
        currentSize -= fileSize;
      }

      // Delete files
      for (final file in filesToRemove) {
        try {
          await file.delete();
        } catch (e) {
          // File might be in use, skip
        }
      }

      if (kDebugMode && filesToRemove.isNotEmpty) {
        log('🗑️ [$CustomCacheManager.key] Removed ${filesToRemove.length} old cached images');
      }
    } catch (e) {
      if (kDebugMode) {
        log('❌ [$CustomCacheManager.key] Cache size enforcement failed: $e');
      }
    }
  }
}