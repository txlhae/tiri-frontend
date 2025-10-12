# Tiri App - Local Storage Documentation

## Executive Summary

**Current Storage Size Issue:** 200-300 MB
**Target Storage Size:** <50 MB for data, <20 MB for app
**Primary Storage Components Identified:**

| Storage Type | Current Limit | Actual Usage | Purpose |
|--------------|---------------|--------------|---------|
| **API Cache** | 2-10 MB | Unknown | Caching API responses |
| **Image Cache** | 8-50 MB | Unknown | Cached network images |
| **Auth Storage** | 100 KB | Small | User authentication data |
| **SharedPreferences** | 5 MB limit | Small | App preferences |
| **Temporary Files** | No strict limit | **Potentially Large** | Image picker, QR codes, temp data |
| **Assets (bundled)** | Fixed | 4.2 MB | Images, icons, fonts |

---

## 1. SharedPreferences Storage (Auth & Preferences)

### Location
- **Platform:** Native device storage (secure)
- **Implementation:** [`lib/services/auth_storage.dart`](lib/services/auth_storage.dart)

### Data Stored
| Key | Type | Purpose | Approx Size |
|-----|------|---------|-------------|
| `access_token` | String | JWT access token | ~500-1000 bytes |
| `refresh_token` | String | JWT refresh token | ~500-1000 bytes |
| `user_data` | JSON String | User profile data | 1-5 KB |
| `account_status` | String | Account status | <100 bytes |
| `next_step` | String | Navigation state | <100 bytes |
| `registration_stage` | JSON String | Registration progress | 1-2 KB |

### Size Limits
- **Maximum:** 100 KB (enforced by `AuthStorage.maxStorageSizeKB`)
- **Auto-cleanup:** Triggered when exceeding 100 KB
- **Actual Usage:** ~5-10 KB (estimated)

### Cleanup Strategy
```dart
// Automatic cleanup in auth_storage.dart:249-284
- Removes non-essential keys when > 100 KB
- Preserves: tokens, user_data, account_status, next_step, registration_stage
```

---

## 2. API Response Cache

### Location
- **Directory:** `<temp_directory>/tiri_api_cache/`
- **Implementation:** [`lib/services/api/api_client.dart`](lib/services/api/api_client.dart:452-520)

### Cache Configuration
| Setting | Development | Production |
|---------|-------------|------------|
| **Enabled** | Yes | Configurable (can be disabled) |
| **Max Size** | 10 MB | 2 MB |
| **Cache Duration** | 1 hour | 1 hour |
| **Auto-cleanup** | Yes | Yes |

### What Gets Cached
- **GET requests only** (api_client.dart:609)
- Community requests (`/api/requests/`)
- User profile data (`/api/profile/users/`)
- Category data (`/api/categories/`)
- Dashboard stats (`/api/dashboard/`)

### Cache Files
- Stored as individual files named by hash of request URL
- Each cached response stored as string
- Old files automatically deleted when size exceeded

### **Potential Issue: Cache Disabled in Release**
```dart
// app_cache_manager.dart:39
ApiClient.initialize(
  enableCache: !kReleaseMode, // Cache DISABLED in production!
  maxCacheSizeMB: 2,
);
```
⚠️ **This means API cache should be ~0 MB in production builds**

---

## 3. Image Cache (Network Images)

### Location
- **Memory Cache:** RAM (up to 50 MB)
- **Disk Cache:** `<temp_directory>/libCachedImageData/`
- **Implementation:**
  - [`lib/services/image_cache_service.dart`](lib/services/image_cache_service.dart)
  - Uses `cached_network_image` package + custom manager

### Cache Configuration
| Setting | Value | Line Reference |
|---------|-------|----------------|
| **Max Memory Size** | 50 images | image_cache_service.dart:38 |
| **Max Memory Bytes** | 50 MB | image_cache_service.dart:39 |
| **Max Disk Cache** | 8 MB | image_cache_service.dart:17 |
| **Max Cached Objects** | 200 images | image_cache_service.dart:164 |
| **Max Cache Age** | 24 hours | image_cache_service.dart:20 |
| **Image Resize Limit** | 800x800 px | image_cache_service.dart:67-68 |

### What Gets Cached
- User profile images
- Request-related images (if any)
- Community images

### Cleanup Strategy
```dart
// Automatic cleanup when > 8 MB
// Removes oldest files first (LRU policy)
// Manual cleanup: ImageCacheService.clearImageCache()
```

### **Potential Issue: Multiple Cache Locations**
The code references multiple cache directories:
1. `libCachedImageData` (standard cached_network_image)
2. `image_cache` (referenced in cache_cleanup_service.dart:74)

**This could lead to duplicate caching!**

---

## 4. Temporary Files & Downloads

### Location
- **Directory:** `<temp_directory>/` (Platform-specific)
  - iOS: `NSTemporaryDirectory()`
  - Android: `getCacheDir()`
- **Managed by:** `path_provider` package

### **⚠️ CRITICAL: This is Likely Your 200-300 MB Issue**

### Potential Sources of Large Temp Files

#### A. Image Picker Files
```dart
// lib/controllers/image_controller.dart:10-17
- When user picks image from gallery
- Creates temporary copy in temp directory
- NOT automatically deleted after upload
```

#### B. QR Code Images
```dart
// lib/screens/widgets/dialog_widgets/qr_code_dialog.dart
- Generates QR code images for sharing
- May create temp files
```

#### C. Downloaded Files
```dart
// api_client.dart:299-327
- File downloads stored in temp directory
- No automatic cleanup mentioned
```

#### D. API Cache (see section 2)

### Cleanup Strategy
```dart
// cache_cleanup_service.dart:93-118
// Deletes files older than 24 hours
- Runs every hour (scheduled)
- Only removes files > 24 hours old
- May not catch rapidly accumulating files
```

### **Problem:**
- Files from image picker accumulate
- No immediate cleanup after image upload
- User could pick 10-20 large images, creating 100+ MB

---

## 5. Bundled Assets (Part of App Size)

### Location
- **Compiled into app bundle**
- Not stored separately on device

### Assets Inventory
| Category | Size | Contents |
|----------|------|----------|
| **Fonts** | 3.8 MB | Poppins (2 weights) + LexendDeca (2 weights) |
| **Images** | 352 KB | Logo, onboarding, auth backgrounds (mostly SVG) |
| **Total** | ~4.2 MB | N/A |

### **Optimization Opportunity:**
- Font files are quite large (3.8 MB for 4 font files)
- Consider using system fonts or smaller subsets
- SVG assets are already optimized (good!)

---

## 6. Firebase & Notifications

### Storage Used
- **Firebase SDK:** Minimal local storage
- **Notification data:** Small (few KB)
- **FCM tokens:** Stored in native keychain/preferences

### No significant storage impact identified

---

## 7. Cache Management Services

### CacheCleanupService
**File:** [`lib/services/cache_cleanup_service.dart`](lib/services/cache_cleanup_service.dart)

**Target Limits:**
```dart
maxApiCacheMB: 5.0      // API responses
maxImageCacheMB: 10.0   // Images
maxTotalCacheMB: 20.0   // Total cache
```

**Cleanup Schedule:**
- Runs every hour automatically
- Cleans API cache if > 5 MB
- Cleans image cache if > 10 MB
- Removes temp files older than 24 hours
- Cleans SharedPreferences if > 5 MB

### AppCacheManager
**File:** [`lib/services/app_cache_manager.dart`](lib/services/app_cache_manager.dart)

**Target Goals:**
```dart
appSizeMB: 20.0     // App binary size target
dataSizeMB: 50.0    // Data storage target
cacheSizeMB: 5.0    // Cache size target
```

**Functions:**
- `initializeCacheSystems()` - Sets up all caches on app start
- `performInitialCleanup()` - Cleans on app launch
- `aggressiveCleanup()` - Emergency cleanup
- `emergencyCleanup()` - Clears everything

---

## Root Cause Analysis: Why 200-300 MB?

### Most Likely Culprits (Ranked)

#### 🔴 **#1: Temporary Image Files (HIGH PRIORITY)**
- **Estimated Impact:** 50-200 MB
- **Root Cause:**
  - `ImagePicker` creates copies of selected images
  - No immediate cleanup after use
  - Files accumulate over time
  - 24-hour cleanup window too long
- **Evidence:**
  ```dart
  // image_controller.dart:10-17
  // Creates File(image.path) but never explicitly deletes
  ```

#### 🟡 **#2: Image Cache Exceeding Limits**
- **Estimated Impact:** 10-50 MB
- **Root Cause:**
  - Multiple cache directories (libCachedImageData + image_cache)
  - Cache enforcement may not be working correctly
  - 200 cached objects × average image size could exceed 8 MB limit
- **Evidence:**
  ```dart
  // Limit is 8 MB but enforcement happens asynchronously
  // May accumulate before cleanup runs
  ```

#### 🟡 **#3: API Cache in Development Builds**
- **Estimated Impact:** 5-10 MB
- **Only affects development builds** (disabled in production)

#### 🟢 **#4: SharedPreferences Bloat**
- **Estimated Impact:** <1 MB
- **Low likelihood** (strict 100 KB limit enforced)

#### 🔴 **#5: Downloaded Files Not Cleaned**
- **Estimated Impact:** Unknown (depends on user behavior)
- **Root Cause:**
  - Downloaded files stored in temp directory
  - No automatic cleanup mechanism
  - Only removed if > 24 hours old

---

## Recommendations to Reduce Storage

### Immediate Actions (Critical)

#### 1. **Cleanup Image Picker Files Immediately**
```dart
// After image upload/processing, delete the temp file:
File tempFile = File(image.path);
if (tempFile.existsSync()) {
  await tempFile.delete();
}
```

#### 2. **Reduce Temp File Cleanup Window**
```dart
// Change from 24 hours to 1 hour
final cutoffTime = DateTime.now().subtract(const Duration(hours: 1));
```

#### 3. **Add Manual Cleanup Trigger**
- Provide "Clear Cache" button in settings
- Show current storage usage
- Let users manually free space

#### 4. **Reduce Image Cache Limits**
```dart
// Current: 8 MB disk, 50 MB memory, 200 objects
// Recommended: 3 MB disk, 20 MB memory, 50 objects
```

### Medium-Term Actions

#### 5. **Implement Aggressive Cleanup on App Background**
```dart
// When app goes to background, clean temp files immediately
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    CacheCleanupService.performCleanup(force: true);
  }
}
```

#### 6. **Consolidate Image Cache Directories**
- Use only ONE image cache location
- Remove duplicate `image_cache` directory references

#### 7. **Optimize Font Files**
- Current: 3.8 MB for 4 font files
- Use font subsetting to include only used glyphs
- Consider Google Fonts API for dynamic loading

#### 8. **Add Storage Monitoring**
```dart
// Log actual storage usage on app start
void logStorageUsage() async {
  final tempDir = await getTemporaryDirectory();
  final totalSize = await _getDirectorySizeMB(tempDir);
  print('Total temp storage: $totalSize MB');
}
```

### Long-Term Actions

#### 9. **Implement Proper File Upload Pipeline**
```dart
// Currently: uploadImage is commented out
// Implement proper upload + cleanup flow
Future<String> uploadAndCleanup(File image) async {
  final url = await uploadImage(image);
  await image.delete(); // Clean up immediately
  return url;
}
```

#### 10. **Use Streaming for Large Files**
- Don't store entire file in memory
- Stream directly from camera to upload

---

## Storage Limits Summary

### Current Configured Limits
```
✅ Auth Storage:        100 KB (enforced)
✅ SharedPreferences:   5 MB (enforced)
⚠️  API Cache:          2-10 MB (may not enforce properly)
⚠️  Image Cache:        8 MB disk (may exceed before cleanup)
❌ Temp Files:          NO LIMIT (only time-based cleanup)
```

### **The Real Problem: Temp Files Have NO Size Limit!**

Only cleanup mechanism:
- Files older than 24 hours deleted
- BUT: No limit on total size
- User can accumulate 500 MB in < 24 hours if picking many images

---

## Monitoring & Debugging Tools

### Check Current Storage Usage
```dart
// Run in your app to see actual usage:
void debugStorage() async {
  final status = await AppCacheManager.getCacheStatus();
  print('API Cache: ${status['api_cache_mb']} MB');
  print('Image Cache: ${status['image_cache_mb']} MB');
  print('Total Cache: ${status['total_cache_mb']} MB');

  final authSize = await AuthStorage.getStorageSizeKB();
  print('Auth Storage: ${authSize} KB');

  // Check temp directory
  final tempDir = await getTemporaryDirectory();
  final tempSize = await _calculateDirSize(tempDir);
  print('Total Temp Dir: ${tempSize / (1024 * 1024)} MB');
}
```

### Enable Debug Logging
All cache services have debug logging (only in debug mode)
- Check console for cache size reports
- Monitor cleanup operations

---

## Files to Review

### Critical Files for Storage Management
1. [`lib/services/cache_cleanup_service.dart`](lib/services/cache_cleanup_service.dart) - Main cleanup logic
2. [`lib/services/image_cache_service.dart`](lib/services/image_cache_service.dart) - Image caching
3. [`lib/services/app_cache_manager.dart`](lib/services/app_cache_manager.dart) - Overall cache coordination
4. [`lib/services/auth_storage.dart`](lib/services/auth_storage.dart) - Auth data storage
5. [`lib/services/api/api_client.dart`](lib/services/api/api_client.dart) - API response caching
6. [`lib/controllers/image_controller.dart`](lib/controllers/image_controller.dart) - Image picking (⚠️ no cleanup)

### Files Creating Temporary Files
1. `lib/controllers/image_controller.dart` - Image picker
2. `lib/screens/widgets/dialog_widgets/qr_code_dialog.dart` - QR code generation
3. Any file using `ImagePicker` or file downloads

---

## Next Steps

### To Identify Exact Storage Issue:

1. **Add Storage Debugging to App**
   - Log temp directory size on app start
   - Log each cache size separately
   - Check actual vs. expected values

2. **Test Storage Accumulation**
   - Pick 10 images from gallery
   - Check temp directory size
   - Wait 1 hour, check again
   - Verify if files are cleaned up

3. **Profile Production Build**
   - Build release version
   - Monitor storage over 1 week of use
   - Identify which directory grows most

4. **Immediate Fix to Deploy**
   ```dart
   // Add to image_controller.dart after image use:
   void cleanupPickedImage() async {
     if (pickedImage.value != null) {
       try {
         await pickedImage.value!.delete();
       } catch (e) {
         // File already deleted or in use
       }
       pickedImage.value = null;
     }
   }
   ```

---

## Conclusion

**The 200-300 MB storage issue is most likely caused by:**

1. **Temporary image files** from `ImagePicker` not being deleted immediately
2. **Image cache** potentially exceeding 8 MB limit before cleanup
3. **No size limit** on temporary directory (only time-based cleanup)

**Recommended immediate fix:**
- Delete temp files immediately after use
- Reduce cleanup window from 24 hours to 1 hour
- Add size-based enforcement to temp directory
- Consolidate image cache to one location

**Long-term solution:**
- Implement proper file lifecycle management
- Add storage monitoring dashboard
- Optimize bundled assets (especially fonts)
- Provide user-facing cache management tools
