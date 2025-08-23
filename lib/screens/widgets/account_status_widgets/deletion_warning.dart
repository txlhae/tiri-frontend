import 'package:flutter/material.dart';
import 'package:tiri/models/auth_models.dart';
import 'package:tiri/services/account_status_service.dart';

/// Deletion Warning Component
/// 
/// Shows a prominent warning when a user's account is at risk of being
/// automatically deleted due to inactivity or pending verification.
class DeletionWarning extends StatelessWidget {
  final AuthWarning warning;
  final VoidCallback? onActionPressed;
  final VoidCallback? onDismiss;
  final bool isDismissible;

  const DeletionWarning({
    super.key,
    required this.warning,
    this.onActionPressed,
    this.onDismiss,
    this.isDismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    final accountStatusService = AccountStatusService.instance;
    final timeRemaining = accountStatusService.getTimeUntilDeletion(warning);
    final isUrgent = _isUrgentWarning();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.red.shade200 : Colors.orange.shade200,
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(isDismissible ? 16 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isUrgent ? Colors.red.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isUrgent ? Icons.warning : Icons.schedule,
                        color: isUrgent ? Colors.red.shade700 : Colors.orange.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUrgent ? 'Urgent: Action Required' : 'Action Required',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isUrgent ? Colors.red.shade800 : Colors.orange.shade800,
                            ),
                          ),
                          Text(
                            'Account deletion in: $timeRemaining',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isUrgent ? Colors.red.shade700 : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Warning message
                Text(
                  warning.message,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.grey.shade800,
                  ),
                ),

                const SizedBox(height: 16),

                // Action button
                if (onActionPressed != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onActionPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUrgent 
                            ? Colors.red.shade600 
                            : Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(_getActionIcon()),
                      label: Text(
                        _getActionText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Dismiss button (if dismissible)
          if (isDismissible && onDismiss != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isUrgentWarning() {
    try {
      final deletionDate = DateTime.parse(warning.deletionDate);
      final now = DateTime.now();
      final timeUntilDeletion = deletionDate.difference(now);
      
      // Consider urgent if less than 24 hours remaining
      return timeUntilDeletion.inHours <= 24;
    } catch (e) {
      return false;
    }
  }

  IconData _getActionIcon() {
    switch (warning.actionRequired) {
      case 'verify_email':
        return Icons.mark_email_read;
      case 'get_approval':
        return Icons.person_add;
      default:
        return Icons.arrow_forward;
    }
  }

  String _getActionText() {
    switch (warning.actionRequired) {
      case 'verify_email':
        return 'Verify Email Now';
      case 'get_approval':
        return 'Contact Referrer';
      default:
        return 'Take Action';
    }
  }
}

/// Compact deletion warning for use in app bars or small spaces
class CompactDeletionWarning extends StatelessWidget {
  final AuthWarning warning;
  final VoidCallback? onTap;

  const CompactDeletionWarning({
    super.key,
    required this.warning,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accountStatusService = AccountStatusService.instance;
    final timeRemaining = accountStatusService.getTimeUntilDeletion(warning);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.shade200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning,
              size: 16,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              'Action needed: $timeRemaining',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 14,
                color: Colors.red.shade700,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet version of deletion warning for more intrusive notifications
class DeletionWarningBottomSheet extends StatelessWidget {
  final AuthWarning warning;
  final VoidCallback? onActionPressed;
  final VoidCallback? onDismiss;

  const DeletionWarningBottomSheet({
    super.key,
    required this.warning,
    this.onActionPressed,
    this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required AuthWarning warning,
    VoidCallback? onActionPressed,
    VoidCallback? onDismiss,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeletionWarningBottomSheet(
        warning: warning,
        onActionPressed: onActionPressed,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountStatusService = AccountStatusService.instance;
    final timeRemaining = accountStatusService.getTimeUntilDeletion(warning);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Warning icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.warning_rounded,
              size: 48,
              color: Colors.red.shade600,
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            'Account Deletion Warning',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Time remaining
          Text(
            'Time remaining: $timeRemaining',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Message
          Text(
            warning.message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Action button
          if (onActionPressed != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onActionPressed?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  warning.actionRequired == 'verify_email' 
                      ? 'Verify Email Now'
                      : 'Take Action',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Dismiss button
          if (onDismiss != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onDismiss?.call();
              },
              child: const Text(
                'Remind me later',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}