import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/location_controller.dart';
import 'package:tiri/models/location_model.dart';
import 'package:tiri/screens/widgets/dialog_widgets/location_picker_dialog.dart';

/// Location selection page
/// This page demonstrates how to use the LocationPickerDialog widget
class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  // Get or create LocationController instance (singleton)
  late final LocationController locationController;

  @override
  void initState() {
    super.initState();
    // Use Get.put with permanent: true to keep it alive, or Get.find if already exists
    if (Get.isRegistered<LocationController>()) {
      locationController = Get.find<LocationController>();
    } else {
      locationController = Get.put(LocationController(), permanent: true);
    }
  }

  void _openLocationPicker() {
    showDialog(
      context: context,
      builder: (context) => LocationPickerDialog(
        initialLocation: locationController.selectedLocation.value,
        onLocationSelected: (location) {
          // Store location in state management
          locationController.setLocation(location);

          // Show success message
          Get.snackbar(
            'Location Set! 📍',
            location.friendlyDisplayName,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade600,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Location',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Obx(() {
            final selectedLocation = locationController.selectedLocation.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Selected Location Display
                if (selectedLocation != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Selected Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedLocation.friendlyDisplayName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildLocationDetail(
                              'Latitude',
                              selectedLocation.latitude
                                  .toStringAsFixed(6),
                            ),
                            const SizedBox(height: 8),
                            _buildLocationDetail(
                              'Longitude',
                              selectedLocation.longitude
                                  .toStringAsFixed(6),
                            ),
                            if (selectedLocation.fullAddress != null) ...[
                              const SizedBox(height: 8),
                              _buildLocationDetail(
                                'Full Address',
                                selectedLocation.fullAddress!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Location Selected',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the button below to select a location',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

                // Select Location Button
                ElevatedButton.icon(
                  onPressed: _openLocationPicker,
                  icon: const Icon(Icons.add_location, size: 24),
                  label: Text(
                    selectedLocation != null
                        ? 'Change Location'
                        : 'Select Location',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLocationDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
