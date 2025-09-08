import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RejectionDialog extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onCancel;
  final Function(String reason) onConfirm;

  const RejectionDialog({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<RejectionDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedPresetReason;
  bool _isCustomReason = false;

  final List<String> _presetReasons = [
    'Incomplete profile information',
    'Unverified contact details',
    'Suspicious activity detected',
    'Does not meet community guidelines',
    'Insufficient verification documents',
    'Custom reason (specify below)',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Reject Registration',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.close),
                      splashRadius: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // User info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rejecting registration for:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Reason selection
                const Text(
                  'Select a reason (optional):',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 12),

                // Preset reasons
                ..._presetReasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(
                      reason,
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: reason,
                    groupValue: _selectedPresetReason,
                    onChanged: (value) {
                      setState(() {
                        _selectedPresetReason = value;
                        _isCustomReason = value == 'Custom reason (specify below)';
                        if (!_isCustomReason) {
                          _reasonController.clear();
                        }
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),

                // Custom reason text field
                if (_isCustomReason) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Custom reason',
                      hintText: 'Please specify the reason for rejection...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    maxLength: 200,
                  ),
                ],

                const SizedBox(height: 24),

                // Info note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The user will be notified of your decision and can see the rejection reason if provided.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reject User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleConfirm() {
    String reason = '';

    if (_selectedPresetReason != null) {
      if (_isCustomReason) {
        reason = _reasonController.text.trim();
        if (reason.isEmpty) {
          Get.snackbar(
            'Custom Reason Required',
            'Please provide a custom reason or select a different option.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }
      } else {
        reason = _selectedPresetReason!;
      }
    }

    widget.onConfirm(reason);
  }
}