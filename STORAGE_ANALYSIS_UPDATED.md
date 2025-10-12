# Tiri App - Storage Analysis (UPDATED)

## 🎯 The Real Problem: Profile Image Caching

### What I Found

Your app **DOES cache images** - specifically **user profile pictures**. After reviewing the code, here's what's actually happening:

## Images Being Cached

### ✅ **User Profile Pictures**
Used extensively throughout the app:

| Screen/Component | Image Source | Line Reference |
|------------------|--------------|----------------|
| Community Request Cards | `request.requester.imageUrl` | [community_requests.dart:119-121](lib/screens/widgets/home_widgets/community_requests.dart:119-121) |
| Profile Screen | `user.imageUrl` | [profile_screen.dart:57](lib/screens/profile_screen.dart:57) |
| Chat Interface | User avatars | Multiple locations |
| Feedback Screens | Volunteer/requester avatars | [feedback.dart](lib/screens/feedback.dart) |
| My Helps | User avatars | [my_helps.dart](lib/screens/my_helps.dart) |
| Edit Profile Dialog | Current profile pic | [edit_dialog.dart:114](lib/screens/widgets/dialog_widgets/edit_dialog.dart:114) |

### How Images Are Loaded

```dart
// Method 1: Direct NetworkImage (NO caching helper used!)
CircleAvatar(
  backgroundImage: request.requester?.imageUrl != null
    ? NetworkImage(request.requester!.imageUrl!)  // ← Not using CachedNetworkImage!
    : null,
)

// Method 2: Same pattern everywhere
backgroundImage: user?.imageUrl != null
  ? NetworkImage(user!.imageUrl!)
  : null
```

## 🔴 **CRITICAL FINDING: You're NOT Using Your Cache Service!**

### What I Expected to Find
```dart
// Using your custom cache service
ImageCacheService.getCachedImage(
  imageUrl: user.imageUrl,
  width: 60,
  height: 60,
)
```

### What's Actually Happening
```dart
// Direct NetworkImage everywhere - Flutter's default cache
NetworkImage(user.imageUrl)
```

## The Real Storage Issue

### Flutter's Default Image Cache (What You're Using)

When you use `NetworkImage()` directly, Flutter uses its **built-in image cache**:

| Setting | Default Value | Impact |
|---------|---------------|---------|
| **Memory Cache** | 100 MB | Stores images in RAM |
| **Disk Cache** | ~1 GB | Can grow very large! |
| **Max Images** | 1000 images | No strict limit |
| **Cache Location** | `NSURLCache` (iOS) / `OkHttp` (Android) | Native HTTP caching |
| **Cleanup** | OS-managed | Unpredictable timing |

### Your Custom Image Cache (NOT Being Used)

You built a proper cache system but **never use it**:

```dart
// lib/services/image_cache_service.dart
static const double maxCacheSizeMB = 8.0;  // ← Ignored
static const int maxCacheAgeHours = 24;    // ← Ignored
maxNrOfCacheObjects: 200,                   // ← Ignored
```

**These limits don't apply** because you're using `NetworkImage()` instead of `ImageCacheService.getCachedImage()`.

## Why This Causes 200-300 MB Storage

### Scenario: Active User Browsing

1. User opens app → Views community requests
2. **Each request card shows requester avatar** = ~20 images loaded
3. User scrolls through 100 requests over a week
4. **100 profile images cached** × 2-3 MB each = **200-300 MB**

### Where This Storage Lives

#### iOS
```
Library/Caches/
  └── com.apple.nsurlsessiond/
      └── Downloads/
          └── [Hundreds of cached profile images]
```

#### Android
```
/data/data/com.example.tiri/cache/
  └── OkHttp/
      └── [Cached images]
```

### The Cache Never Expires Because:
1. ❌ You're not using your 8 MB limit
2. ❌ You're not using your 24-hour expiry
3. ❌ You're not using your 200 object limit
4. ✅ You're using the OS default cache (1 GB+)

## 🎯 Root Cause Summary

| Issue | Impact | Fix Priority |
|-------|--------|--------------|
| **Using `NetworkImage` instead of `CachedNetworkImage`** | HIGH - No cache control | 🔴 CRITICAL |
| **Built custom cache service but never use it** | HIGH - Wasted effort, no benefits | 🔴 CRITICAL |
| **No cache size limits enforced** | HIGH - Grows to 200-300 MB | 🔴 CRITICAL |
| **Image picker temp files** | LOW - Rare usage (profile edit only) | 🟡 MINOR |
| **API cache** | NONE - Disabled in production | ✅ OK |

## Immediate Fix Strategy

### Option 1: Use Your Existing Cache Service (Recommended)

Replace all `NetworkImage()` calls with your cache service:

```dart
// BEFORE (current code)
CircleAvatar(
  backgroundImage: user.imageUrl != null
    ? NetworkImage(user.imageUrl!)
    : null,
)

// AFTER (using your cache service)
Widget buildAvatar(String? imageUrl) {
  if (imageUrl == null) {
    return CircleAvatar(child: Icon(Icons.person));
  }

  return ClipOval(
    child: ImageCacheService.getCachedImage(
      imageUrl: imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
    ),
  );
}
```

### Option 2: Reduce Default Cache Limits

If you want to keep using `NetworkImage`, reduce Flutter's cache:

```dart
// In main.dart or app initialization
void setupImageCache() {
  PaintingBinding.instance.imageCache.maximumSize = 50;      // Max 50 images
  PaintingBinding.instance.imageCache.maximumSizeBytes = 10 << 20; // 10 MB
}
```

But this won't affect disk cache, only memory.

## Files That Need Changes

### 🔴 Critical - Replace NetworkImage Usage

1. **[lib/screens/widgets/home_widgets/community_requests.dart:119-127](lib/screens/widgets/home_widgets/community_requests.dart:119-127)**
   - Community request cards (most frequent usage)

2. **[lib/screens/profile_screen.dart](lib/screens/profile_screen.dart)**
   - Profile avatar display

3. **[lib/screens/my_helps.dart](lib/screens/my_helps.dart)**
   - Helper avatars

4. **[lib/screens/feedback.dart](lib/screens/feedback.dart)**
   - Feedback user avatars

5. **[lib/screens/widgets/dialog_widgets/edit_dialog.dart:114](lib/screens/widgets/dialog_widgets/edit_dialog.dart:114)**
   - Edit profile dialog

### Search & Replace Pattern

```bash
# Find all NetworkImage usage
grep -r "NetworkImage(" lib/screens --include="*.dart"
```

## Why You Built a Cache Service You're Not Using

Looking at your code:

```dart
// lib/services/image_cache_service.dart - Built but unused
static Widget getCachedImage({
  required String imageUrl,
  double? width,
  double? height,
  // ... configured with 8 MB limit, 24h expiry
})

// But everywhere in your app:
NetworkImage(user.imageUrl) // ← Using Flutter default instead
```

**You have a perfectly good cache service with proper limits, but you're not using it!**

## Estimated Impact of Fix

### Before Fix (Current)
- **Profile image cache:** 200-300 MB (uncontrolled)
- **Cache location:** OS-managed, unpredictable
- **Cleanup:** Whenever OS decides

### After Fix (Using Your Cache Service)
- **Profile image cache:** 8 MB max (enforced)
- **Cache location:** `libCachedImageData/` (controlled)
- **Cleanup:** Every 24 hours automatically
- **Max images:** 200 objects
- **Image resize:** 800×800px max

**Expected reduction: 200-300 MB → 8 MB** (96-97% reduction)

## Quick Win: Update Community Request Cards

This is your highest-traffic image usage:

```dart
// lib/screens/widgets/home_widgets/community_requests.dart
// BEFORE
ListTile(
  leading: CircleAvatar(
    backgroundImage: request.requester?.imageUrl != null
      ? NetworkImage(request.requester!.imageUrl!)
      : null,
    radius: 30,
    child: request.requester?.imageUrl == null
      ? const Icon(Icons.person)
      : null,
  ),
  // ...
)

// AFTER
ListTile(
  leading: request.requester?.imageUrl != null
    ? ClipOval(
        child: ImageCacheService.getCachedImage(
          imageUrl: request.requester!.imageUrl!,
          width: 60,
          height: 60,
        ),
      )
    : CircleAvatar(
        radius: 30,
        child: const Icon(Icons.person),
      ),
  // ...
)
```

## Alternative: Simple Fix Without Your Cache Service

If you want a simpler fix without refactoring:

```dart
// Add to pubspec.yaml (you already have this!)
dependencies:
  cached_network_image: ^3.3.1  # ✅ Already in your pubspec!

// Replace NetworkImage with CachedNetworkImage
CircleAvatar(
  radius: 30,
  child: CachedNetworkImage(
    imageUrl: user.imageUrl ?? "",
    imageBuilder: (context, imageProvider) => Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
    ),
    placeholder: (context, url) => Icon(Icons.person),
    errorWidget: (context, url, error) => Icon(Icons.person),
    maxWidthDiskCache: 800,
    maxHeightDiskCache: 800,
  ),
)
```

But you **already built a wrapper for this** in `ImageCacheService` - just use it!

## Summary

**You're experiencing 200-300 MB storage because:**

1. ✅ You cache profile images (requester avatars on every request)
2. ❌ You use `NetworkImage()` which has 1 GB+ default cache
3. ❌ You built a proper cache service but never use it
4. ❌ Your 8 MB limit is ignored because code doesn't use the service

**The fix:**
- Replace all `NetworkImage(url)` with `ImageCacheService.getCachedImage(imageUrl: url)`
- This will enforce your 8 MB limit, 24-hour expiry, and 200 object max
- Expected storage reduction: **200-300 MB → 8 MB**

**Easiest first step:**
Update community request cards (highest usage) to use your cache service.
