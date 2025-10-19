import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tiri/models/location_model.dart';

class LocationPickerDialog extends StatefulWidget {
  final LocationModel? initialLocation;
  final Function(LocationModel) onLocationSelected;

  const LocationPickerDialog({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

  // Default location (Kochi, Kerala)
  LatLng _selectedPosition = const LatLng(9.9312, 76.2673);
  LocationModel? _selectedLocation;
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  String? _errorMessage;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedPosition = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _selectedLocation = widget.initialLocation;
      _updateMarker();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedPosition,
          draggable: true,
          onDragEnd: (newPosition) {
            _onPositionChanged(newPosition);
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      };
    });
  }

  Future<void> _onPositionChanged(LatLng position) async {
    setState(() {
      _selectedPosition = position;
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final location = LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          locality: placemark.locality,
          subLocality: placemark.subLocality,
          administrativeArea: placemark.administrativeArea,
          country: placemark.country,
          postalCode: placemark.postalCode,
          fullAddress:
              '${placemark.subLocality ?? ''} ${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}',
          displayName:
              '${placemark.locality ?? placemark.subLocality ?? ''}, ${placemark.administrativeArea ?? ''}',
        );

        setState(() {
          _selectedLocation = location;
          _searchController.text = location.friendlyDisplayName;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not fetch location details';
        _isLoadingLocation = false;
      });
    }

    _updateMarker();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newPosition = LatLng(position.latitude, position.longitude);

      // Animate camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPosition, 15),
      );

      await _onPositionChanged(newPosition);

      Get.snackbar(
        'Location Found',
        'Current location has been set',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('permissions')
            ? 'Location permission denied. Please enable in settings.'
            : 'Could not get current location. Please try again.';
        _isLoadingLocation = false;
      });

      Get.snackbar(
        'Location Error',
        _errorMessage!,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a location to search';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final location = locations.first;
        final newPosition = LatLng(location.latitude, location.longitude);

        // Animate camera to searched location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 15),
        );

        await _onPositionChanged(newPosition);

        // Unfocus the search field
        FocusScope.of(context).unfocus();
      } else {
        setState(() {
          _errorMessage = 'Location not found';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not find location. Try different keywords.';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _handleConfirmLocation() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(_selectedLocation!);
      Get.back();
    } else {
      Get.snackbar(
        'No Location Selected',
        'Please select a location on the map',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 16 : 40,
        vertical: 24,
      ),
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.85,
        constraints: BoxConstraints(
          maxWidth: screenWidth < 600 ? screenWidth - 32 : 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 140, 170, 1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 32,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Select Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search location...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color.fromRGBO(0, 140, 170, 1),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: _searchLocation,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSearching
                            ? null
                            : () => _searchLocation(_searchController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSearching
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search, size: 24),
                      ),
                    ],
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Current Location Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: const Text('Use Current Location'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(
                      color: Color.fromRGBO(0, 140, 170, 1),
                    ),
                    foregroundColor: const Color.fromRGBO(0, 140, 170, 1),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Selected Location Display
            if (_selectedLocation != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Location',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _selectedLocation!.friendlyDisplayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Map View
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedPosition,
                          zoom: 13,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        onTap: (position) {
                          _onPositionChanged(position);
                        },
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: false,
                      ),
                      if (_isLoadingLocation)
                        Container(
                          color: Colors.black26,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Helper Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap on map or drag the pin to select location',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _handleConfirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Confirm Location',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
