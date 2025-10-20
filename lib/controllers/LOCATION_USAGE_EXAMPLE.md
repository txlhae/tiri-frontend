# Location Controller Usage Guide

## Overview
The `LocationController` stores the user's selected location in GetX state management, making it accessible throughout the app for API calls and UI display.

## Accessing Location Data

### 1. In any Controller or Widget

```dart
import 'package:get/get.dart';
import 'package:tiri/controllers/location_controller.dart';

// Get the controller instance
final locationController = Get.find<LocationController>();

// Check if location is set
if (locationController.hasLocation) {
  // Location is available
  print('Location: ${locationController.displayName}');
}

// Get latitude and longitude for API calls
double? lat = locationController.latitude;
double? lng = locationController.longitude;
```

### 2. Making API Calls with Location

```dart
// Example: Fetch nearby requests
Future<void> fetchNearbyRequests() async {
  final locationController = Get.find<LocationController>();

  if (!locationController.hasLocation) {
    // No location selected, show error or use default
    print('No location selected');
    return;
  }

  // Make API call with location coordinates
  final response = await apiService.get(
    '/api/requests/nearby',
    params: {
      'latitude': locationController.latitude,
      'longitude': locationController.longitude,
      'radius': 10, // km
    },
  );

  // Process response...
}
```

### 3. Using Location in RequestController

You can integrate this with your existing `RequestController`:

```dart
// In lib/controllers/request_controller.dart

import 'package:tiri/controllers/location_controller.dart';

class RequestController extends GetxController {
  final LocationController _locationController = Get.find<LocationController>();

  Future<void> getCommunityRequests() async {
    // Use location if available
    if (_locationController.hasLocation) {
      // Filter by location
      final params = {
        'latitude': _locationController.latitude,
        'longitude': _locationController.longitude,
      };
      // Make API call with location params...
    } else {
      // Make API call without location filter...
    }
  }
}
```

### 4. Reactive UI Updates

Use `Obx` to automatically update UI when location changes:

```dart
Obx(() {
  final location = Get.find<LocationController>().selectedLocation.value;

  return Text(
    location != null
      ? 'Near ${location.friendlyDisplayName}'
      : 'Select location',
  );
})
```

## Available Properties

- `selectedLocation.value` - Full LocationModel object (nullable)
- `hasLocation` - Boolean, true if location is selected
- `latitude` - Double?, latitude coordinate
- `longitude` - Double?, longitude coordinate
- `displayName` - String, user-friendly location name
- `coordinates` - String, formatted coordinates for debugging

## Available Methods

- `setLocation(LocationModel location)` - Store a new location
- `clearLocation()` - Remove the stored location

## Integration with Backend

When making API requests for nearby service requests:

```dart
// Example API endpoint usage
GET /api/requests?latitude=9.9312&longitude=76.2673&radius=10

// The backend can use these coordinates to:
// 1. Calculate distance from request locations
// 2. Filter requests within radius
// 3. Sort by proximity
```
