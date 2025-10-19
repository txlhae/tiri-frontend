import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/models/location_model.dart';
import 'package:tiri/screens/widgets/dialog_widgets/location_picker_dialog.dart';

/// Demo page to test the Location Picker Dialog
/// This page demonstrates how to use the LocationPickerDialog widget
class LocationDemoPage extends StatefulWidget {
  const LocationDemoPage({super.key});

  @override
  State<LocationDemoPage> createState() => _LocationDemoPageState();
}

class _LocationDemoPageState extends State<LocationDemoPage> {
  LocationModel? _selectedLocation;

  void _openLocationPicker() {
    showDialog(
      context: context,
      builder: (context) => LocationPickerDialog(
        initialLocation: _selectedLocation,
        onLocationSelected: (location) {
          setState(() {
            _selectedLocation = location;
          });

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
          'Location Picker Demo',
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'How to Use',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionItem(
                      '1',
                      'Tap "Select Location" button below',
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionItem(
                      '2',
                      'Search for a location or use current location',
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionItem(
                      '3',
                      'Tap on map or drag the pin to adjust',
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionItem(
                      '4',
                      'Confirm to save the location',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Selected Location Display
              if (_selectedLocation != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
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
                                    _selectedLocation!.friendlyDisplayName,
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
                              _selectedLocation!.latitude
                                  .toStringAsFixed(6),
                            ),
                            const SizedBox(height: 8),
                            _buildLocationDetail(
                              'Longitude',
                              _selectedLocation!.longitude
                                  .toStringAsFixed(6),
                            ),
                            if (_selectedLocation!.fullAddress != null) ...[
                              const SizedBox(height: 8),
                              _buildLocationDetail(
                                'Full Address',
                                _selectedLocation!.fullAddress!,
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
                const SizedBox(height: 24),
              ],

              // Select Location Button
              ElevatedButton.icon(
                onPressed: _openLocationPicker,
                icon: const Icon(Icons.add_location, size: 24),
                label: Text(
                  _selectedLocation != null
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

              const Spacer(),

              // API Data Preview (for developers)
              if (_selectedLocation != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API Data (send to backend)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '{\n'
                          '  "latitude": ${_selectedLocation!.latitude},\n'
                          '  "longitude": ${_selectedLocation!.longitude},\n'
                          '  "displayName": "${_selectedLocation!.friendlyDisplayName}"\n'
                          '}',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
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
