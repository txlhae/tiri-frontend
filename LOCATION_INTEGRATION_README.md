# Location Integration Guide

## Overview

This guide explains the location selection feature integrated into the Tiri app. The feature allows users to:
- Search for locations by typing an address
- Use their current location
- Select a location by tapping on a map
- Drag a pin to adjust the selected location

## Components

### 1. Location Model (`lib/models/location_model.dart`)

The `LocationModel` stores location data including:
- **latitude** and **longitude**: GPS coordinates sent to the backend
- **displayName**: User-friendly location name (e.g., "Kakkanad, Kochi")
- **locality**: Main area/district
- **subLocality**: Sub-area within the locality
- **administrativeArea**: City or state
- **fullAddress**: Complete address string

### 2. Location Picker Dialog (`lib/screens/widgets/dialog_widgets/location_picker_dialog.dart`)

A full-featured popup dialog that provides:
- **Search functionality**: Type location names to search
- **Current location button**: Automatically detect and use current GPS location
- **Interactive map**: Tap anywhere or drag the pin to select location
- **Location preview**: Shows the selected location name before confirming

### 3. Demo Page (`lib/screens/location_demo_page.dart`)

A demonstration page showing:
- How to integrate the location picker
- Visual display of selected location
- API data format (latitude, longitude, displayName)
- Step-by-step instructions for users

## Packages Used

The following Flutter packages are required (already added to `pubspec.yaml`):

- **google_maps_flutter** (^2.12.3): Provides the interactive map interface
- **geolocator** (^13.0.2): Gets current device location (FREE - no API key needed)
- **geocoding** (^3.0.0): Converts coordinates to addresses and vice versa (FREE - no API key needed)

### Why These Providers?

- **geolocator**: Uses native platform APIs (Android Location Services, iOS Core Location) - completely free
- **geocoding**: Uses native platform geocoding services - no API keys or costs
- **google_maps_flutter**: Requires Google Maps API key but provides the best map experience

## Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<!-- Location permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS (`ios/Runner/Info.plist`)

```xml
<!-- Location Permission for Maps -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Tiri uses your location to show nearby users and services on the map.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Tiri uses your location to help you select your current location when creating requests.</string>
```

## How to Use

### Basic Integration Example

```dart
import 'package:tiri/models/location_model.dart';
import 'package:tiri/screens/widgets/dialog_widgets/location_picker_dialog.dart';

// In your StatefulWidget or GetX controller:
LocationModel? selectedLocation;

void openLocationPicker() {
  showDialog(
    context: context,
    builder: (context) => LocationPickerDialog(
      initialLocation: selectedLocation, // Optional: pre-fill with existing location
      onLocationSelected: (location) {
        // Handle the selected location
        setState(() {
          selectedLocation = location;
        });

        // Access location data:
        print('Latitude: ${location.latitude}');
        print('Longitude: ${location.longitude}');
        print('Display Name: ${location.friendlyDisplayName}');
      },
    ),
  );
}
```

### Data to Send to Backend

When creating or updating a request, send the following data:

```json
{
  "latitude": 9.931233,
  "longitude": 76.267303,
  "displayName": "Kakkanad, Kochi"
}
```

The backend only needs `latitude` and `longitude` for precise location tracking. The `displayName` is stored for display purposes in the frontend.

### Displaying Location in UI

Use the `friendlyDisplayName` getter for user-friendly display:

```dart
Text(selectedLocation?.friendlyDisplayName ?? 'No location selected')
// Output: "Kakkanad, Kochi" or "Thrikkakara, Kochi"
```

## Testing

### Try the Demo Page

1. Run the app
2. Tap the **Maps icon** (location pin) in the home screen header
3. You'll see the Location Demo Page with:
   - Instructions on how to use the picker
   - A "Select Location" button
   - Display of selected location with all details

### Test Features

1. **Search**: Type "Kochi" or "Kakkanad" and press Enter or tap the search button
2. **Current Location**: Tap "Use Current Location" (may require permission)
3. **Map Interaction**:
   - Tap anywhere on the map to select that location
   - Drag the blue pin to adjust the location
   - Zoom and pan the map as needed
4. **Confirm**: Tap "Confirm Location" to save

## Integration Steps for Add Request Page

When you're ready to integrate into the Add Request page:

1. **Import the dialog**:
```dart
import 'package:tiri/screens/widgets/dialog_widgets/location_picker_dialog.dart';
import 'package:tiri/models/location_model.dart';
```

2. **Add to controller** (RequestController):
```dart
Rx<LocationModel?> selectedLocation = Rx<LocationModel?>(null);

void openLocationPicker(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => LocationPickerDialog(
      initialLocation: selectedLocation.value,
      onLocationSelected: (location) {
        selectedLocation.value = location;
        // Update the location text field
        locationController.value.text = location.friendlyDisplayName;
      },
    ),
  );
}
```

3. **Update the location field** in `add_request_page.dart`:
```dart
Obx(() => CustomFormField(
  hintText: "Location",
  haveObscure: false,
  textController: controller.locationController.value,
  readOnly: true, // Make it read-only
  onTapped: () => controller.openLocationPicker(context), // Open picker on tap
  iconSuffix: 'assets/icons/location_icon.svg', // Add location icon
)),
```

4. **Send to API**:
```dart
final requestData = {
  'title': title,
  'description': description,
  'latitude': selectedLocation.value?.latitude,
  'longitude': selectedLocation.value?.longitude,
  'location': selectedLocation.value?.friendlyDisplayName,
  // ... other fields
};
```

## Map API Key (Important!)

### Google Maps requires an API key for production use:

1. **Get a Google Maps API Key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing
   - Enable "Maps SDK for Android" and "Maps SDK for iOS"
   - Create credentials → API Key
   - Restrict the key to your app's package name for security

2. **Add to Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<application>
  <meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
</application>
```

3. **Add to iOS** (`ios/Runner/AppDelegate.swift`):
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**Note**: For development/testing, the map may work without an API key in some cases, but you'll see a "For development purposes only" watermark.

## Features Summary

✅ **Search locations** by typing address/place names
✅ **Get current location** automatically using GPS
✅ **Interactive map** with tap-to-select functionality
✅ **Draggable pin** for precise location adjustment
✅ **Reverse geocoding** - converts coordinates to readable addresses
✅ **Free geocoding** - uses platform-native services (no API costs)
✅ **User-friendly display names** - shows "Locality, Area" format
✅ **Accurate coordinates** - sends precise lat/long to backend
✅ **Permission handling** - requests location permissions when needed
✅ **Error handling** - shows helpful messages for permission denied, location not found, etc.

## Troubleshooting

### Location permission denied
- Check that permissions are added to AndroidManifest.xml and Info.plist
- On iOS simulator, go to Features → Location → Custom Location
- On Android, Settings → Apps → Tiri → Permissions → Location

### Map not loading
- Ensure Google Maps API key is configured
- Check internet connection
- Enable Maps SDK for Android/iOS in Google Cloud Console

### "Location not found" when searching
- Try more specific search terms (e.g., "Kakkanad Kochi" instead of just "Kakkanad")
- Check internet connection (geocoding requires internet)

### Current location not working
- Grant location permission when prompted
- Enable location services on the device
- For iOS simulator: Features → Location → Apple

## Next Steps

Once you're satisfied with the design and functionality:

1. Integrate into the Add Request page (see Integration Steps above)
2. Update the RequestController to handle LocationModel
3. Update the backend API to accept latitude/longitude fields
4. Update the Request Details page to display location on a map
5. Consider adding location filtering for community requests (show nearby requests)

## Design Customization

The location picker follows your app's design system:
- Uses `Color.fromRGBO(0, 140, 170, 1)` as the primary color
- Matches the dialog design of other popups (e.g., IntrestedDialog)
- Rounded corners, shadows, and spacing consistent with app style
- Responsive design that works on different screen sizes

Feel free to adjust colors, fonts, or layouts in `location_picker_dialog.dart` to match your exact requirements!
