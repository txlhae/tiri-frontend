import 'package:flutter/material.dart';
import 'package:tiri/models/auth_models.dart';
import 'package:url_launcher/url_launcher.dart';

/// Approval Status Display Component
/// 
/// Shows the current approval status for users waiting for referrer approval.
/// Includes referrer information, time remaining, and contact options.
class ApprovalStatusDisplay extends StatelessWidget {
  final RegistrationStage registrationStage;
  final VoidCallback? onContactReferrer;
  final VoidCallback? onRefresh;
  final bool showContactButton;
  final EdgeInsets? padding;

  const ApprovalStatusDisplay({
    super.key,
    required this.registrationStage,
    this.onContactReferrer,
    this.onRefresh,
    this.showContactButton = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (registrationStage.status != 'approval_pending') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          _buildStatusHeader(),
          
          const SizedBox(height: 20),
          
          // Referrer information
          if (registrationStage.referrerEmail != null)
            _buildReferrerInfo(),
          
          const SizedBox(height: 20),
          
          // Time remaining
          if (registrationStage.timeRemaining != null)
            _buildTimeRemaining(),
          
          const SizedBox(height: 24),
          
          // Action buttons
          _buildActionButtons(context),
          
          const SizedBox(height: 16),
          
          // Help text
          _buildHelpText(),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.pending_actions,
              color: Colors.orange.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting for Approval',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your referrer needs to approve your account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferrerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Your Referrer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            registrationStage.referrerEmail ?? 'Unknown',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color.fromRGBO(0, 140, 170, 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRemaining() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Time Remaining',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                registrationStage.timeRemaining ?? 'Unknown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Contact referrer button
        if (showContactButton && registrationStage.referrerEmail != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onContactReferrer ?? () => _contactReferrer(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.email),
              label: const Text(
                'Contact Referrer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        if (showContactButton && onRefresh != null) const SizedBox(height: 12),

        // Refresh status button
        if (onRefresh != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRefresh,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color.fromRGBO(0, 140, 170, 1),
                side: const BorderSide(
                  color: Color.fromRGBO(0, 140, 170, 1),
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Check Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHelpText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.grey.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'What happens next?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Your referrer will receive an email notification\n'
            '• They can approve or reject your application\n'
            '• You\'ll be notified immediately of their decision\n'
            '• If no response, your application will expire',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _contactReferrer(BuildContext context) async {
    final referrerEmail = registrationStage.referrerEmail;
    if (referrerEmail == null) return;

    final subject = Uri.encodeComponent('TIRI Account Approval Request');
    final body = Uri.encodeComponent(
      'Hi,\n\n'
      'I\'ve registered for TIRI using your referral code and am waiting for your approval. '
      'Could you please check your email and approve my account?\n\n'
      'Thanks!\n'
    );
    
    final emailUri = Uri.parse('mailto:$referrerEmail?subject=$subject&body=$body');
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          _showEmailNotAvailableDialog(context, referrerEmail);
        }
      }
    } catch (e) {
      // Error handled silently
      if (context.mounted) {
        _showEmailNotAvailableDialog(context, referrerEmail);
      }
    }
  }

  void _showEmailNotAvailableDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Referrer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Email app is not available. You can contact your referrer at:'),
            const SizedBox(height: 12),
            SelectableText(
              email,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(0, 140, 170, 1),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Let them know you\'re waiting for account approval.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Compact approval status for use in app bars or cards
class CompactApprovalStatus extends StatelessWidget {
  final RegistrationStage registrationStage;
  final VoidCallback? onTap;

  const CompactApprovalStatus({
    super.key,
    required this.registrationStage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (registrationStage.status != 'approval_pending') {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.orange.shade200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pending_actions,
              size: 16,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              'Pending approval',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade700,
              ),
            ),
            if (registrationStage.timeRemaining != null) ...[
              const SizedBox(width: 4),
              Text(
                '• ${registrationStage.timeRemaining}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade600,
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 14,
                color: Colors.orange.shade700,
              ),
            ],
          ],
        ),
      ),
    );
  }
}