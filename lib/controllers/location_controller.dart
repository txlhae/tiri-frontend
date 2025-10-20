import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiri/models/location_model.dart';
import 'package:tiri/services/request_service.dart';

class LocationController extends GetxController {
  // Observable selected location
  final Rx<LocationModel?> selectedLocation = Rx<LocationModel?>(null);

  // Get RequestService instance
  RequestService get _requestService => Get.find<RequestService>();

  // SharedPreferences key for storing location
  static const String _locationKey = 'user_selected_location';

  @override
  void onInit() {
    super.onInit();
    _loadLocationFromStorage();
  }

  // Load location from persistent storage
  Future<void> _loadLocationFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationJson = prefs.getString(_locationKey);

      if (locationJson != null) {
        final locationMap = json.decode(locationJson) as Map<String, dynamic>;
        selectedLocation.value = LocationModel.fromJson(locationMap);
      }
    } catch (e) {
      // Failed to load location from storage
    }
  }

  // Save location to persistent storage
  Future<void> _saveLocationToStorage(LocationModel location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationJson = json.encode(location.toJson());
      await prefs.setString(_locationKey, locationJson);
    } catch (e) {
      // Failed to save location to storage
    }
  }

  // Update selected location and persist it
  Future<void> setLocation(LocationModel location) async {
    selectedLocation.value = location;
    await _saveLocationToStorage(location);

    // Update location on backend for nearby service request notifications
    try {
      await _requestService.updateUserLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.fullAddress,
        city: location.locality,
        state: location.administrativeArea,
        postalCode: location.postalCode,
      );
    } catch (e) {
      // Silently handle error - location is still saved locally
      // User can still use the app even if backend update fails
    }
  }

  // Clear selected location and remove from storage
  Future<void> clearLocation() async {
    selectedLocation.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_locationKey);
    } catch (e) {
      // Failed to clear location from storage
    }
  }

  // Check if location is selected
  bool get hasLocation => selectedLocation.value != null;

  // Get latitude for API calls
  double? get latitude => selectedLocation.value?.latitude;

  // Get longitude for API calls
  double? get longitude => selectedLocation.value?.longitude;

  // Get display name for UI
  String get displayName =>
      selectedLocation.value?.friendlyDisplayName ?? 'Select Location';

  // Get formatted coordinates for debugging
  String get coordinates {
    if (selectedLocation.value == null) return 'No location selected';
    return '${selectedLocation.value!.latitude.toStringAsFixed(4)}, ${selectedLocation.value!.longitude.toStringAsFixed(4)}';
  }
}
