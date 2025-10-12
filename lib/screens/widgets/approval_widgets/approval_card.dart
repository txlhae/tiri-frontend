import 'package:flutter/material.dart';
import 'package:tiri/models/approval_request_model.dart';

class ApprovalCard extends StatelessWidget {
  final ApprovalRequest approval;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool isExpanded;
  final VoidCallback? onTap;

  const ApprovalCard({
    super.key,
    required this.approval,
    required this.onApprove,
    required this.onReject,
    this.isExpanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with name and time
              Row(
                children: [
                  // Profile picture placeholder
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color.fromRGBO(0, 140, 170, 0.1),
                    backgroundImage: approval.newUserProfileImage != null
                        ? NetworkImage(approval.newUserProfileImage!)
                        : null,
                    child: approval.newUserProfileImage == null
                        ? Text(
                            approval.newUserName.isNotEmpty
                                ? approval.newUserName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color.fromRGBO(0, 140, 170, 1),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Name and email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          approval.newUserName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          approval.newUserEmail,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Time remaining with color coding
                  _buildTimeRemaining(),
                ],
              ),
              
              if (isExpanded) ...[
                const SizedBox(height: 16),
                _buildExpandedDetails(),
              ] else ...[
                const SizedBox(height: 12),
                _buildCompactDetails(),
              ],
              
              const SizedBox(height: 16),
              
              // Action buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRemaining() {
    final timeRemaining = approval.timeRemaining;
    Color color;
    IconData icon;

    if (approval.isExpired) {
      color = Colors.red;
      icon = Icons.schedule;
    } else if (approval.isExpiringSoon) {
      color = Colors.orange;
      icon = Icons.schedule;
    } else {
      color = const Color.fromRGBO(0, 140, 170, 1);
      icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            timeRemaining,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetails() {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            Icons.location_on,
            approval.newUserCountry,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDetailItem(
            Icons.code,
            approval.referralCodeUsed,
            const Color.fromRGBO(0, 140, 170, 1),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                Icons.location_on,
                approval.newUserCountry,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailItem(
                Icons.code,
                approval.referralCodeUsed,
                const Color.fromRGBO(0, 140, 170, 1),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        if (approval.newUserPhone != null)
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.phone,
                  approval.newUserPhone!,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  Icons.access_time,
                  _formatDate(approval.requestedAt),
                  Colors.grey,
                ),
              ),
            ],
          ),
        
        const SizedBox(height: 8),
        
        // Request date
        _buildDetailItem(
          Icons.calendar_today,
          'Requested on ${_formatDate(approval.requestedAt)}',
          Colors.grey,
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: approval.isExpired ? null : onReject,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: ElevatedButton.icon(
            onPressed: approval.isExpired ? null : onApprove,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }
}