import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/models/approval_request_model.dart';
import 'package:kind_clock/screens/widgets/approval_widgets/approval_card.dart';
import 'package:kind_clock/screens/widgets/dialog_widgets/rejection_dialog.dart';

class ApprovalDashboardScreen extends StatefulWidget {
  const ApprovalDashboardScreen({super.key});

  @override
  State<ApprovalDashboardScreen> createState() => _ApprovalDashboardScreenState();
}

class _ApprovalDashboardScreenState extends State<ApprovalDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AuthController authController;
  late TabController _tabController;
  final GlobalKey<RefreshIndicatorState> _pendingRefreshKey = GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _historyRefreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load initial data
    _loadInitialData();
  }

  void _loadInitialData() async {
    await authController.fetchPendingApprovals();
    await authController.fetchApprovalHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Header with curved design like My Helps
          SafeArea(
            child: Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(0, 140, 170, 1),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Manage Approvals',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    indicator: const BoxDecoration(),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                    tabs: [
                      Obx(() => Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Pending'),
                            if (authController.pendingApprovalsCount.value > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${authController.pendingApprovalsCount.value}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )),
                      const Tab(text: 'History'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return RefreshIndicator(
      key: _pendingRefreshKey,
      onRefresh: () => authController.fetchPendingApprovals(),
      child: Obx(() {
        if (authController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Show error state if there's an error
        if (authController.pendingApprovalsError.value) {
          return _buildErrorState(
            icon: Icons.error_outline,
            title: 'Failed to Load Approvals',
            subtitle: authController.pendingApprovalsErrorMessage.value,
            color: Colors.red,
            onRetry: () => authController.fetchPendingApprovals(),
          );
        }

        // Show empty state only if no error and no pending approvals
        if (authController.pendingApprovals.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'All Caught Up!',
            subtitle: 'No pending approvals at the moment.',
            color: const Color.fromRGBO(0, 140, 170, 1),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: authController.pendingApprovals.length,
          itemBuilder: (context, index) {
            final approval = authController.pendingApprovals[index];
            return ApprovalCard(
              approval: approval,
              onApprove: () => _showApprovalConfirmation(approval),
              onReject: () => _showRejectionDialog(approval),
              onTap: () => _showApprovalDetails(approval),
            );
          },
        );
      }),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      key: _historyRefreshKey,
      onRefresh: () => authController.fetchApprovalHistory(),
      child: Obx(() {
        if (authController.isLoading.value && authController.approvalHistory.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Show error state if there's an error
        if (authController.approvalHistoryError.value) {
          return _buildErrorState(
            icon: Icons.error_outline,
            title: 'Failed to Load History',
            subtitle: authController.approvalHistoryErrorMessage.value,
            color: Colors.red,
            onRetry: () => authController.fetchApprovalHistory(),
          );
        }

        // Show empty state only if no error and no history
        if (authController.approvalHistory.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'No History Yet',
            subtitle: 'Your approval history will appear here once you start managing registrations.',
            color: Colors.grey,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: authController.approvalHistory.length,
          itemBuilder: (context, index) {
            final approval = authController.approvalHistory[index];
            return _buildHistoryCard(approval);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: color.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: color.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ApprovalRequest approval) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (approval.status) {
      case 'approved':
        statusIcon = Icons.check_circle;
        statusColor = const Color.fromRGBO(0, 140, 170, 1);
        statusText = 'Approved';
        break;
      case 'rejected':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      case 'expired':
        statusIcon = Icons.schedule;
        statusColor = Colors.orange;
        statusText = 'Expired';
        break;
      default:
        statusIcon = Icons.help;
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and status
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor.withOpacity(0.1),
                  backgroundImage: approval.newUserProfileImage != null
                      ? NetworkImage(approval.newUserProfileImage!)
                      : null,
                  child: approval.newUserProfileImage == null
                      ? Text(
                          approval.newUserName.isNotEmpty
                              ? approval.newUserName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                
                const SizedBox(width: 12),
                
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
                
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Details row
            Row(
              children: [
                Expanded(
                  child: _buildHistoryDetailItem(
                    Icons.location_on,
                    approval.newUserCountry,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                _buildHistoryDetailItem(
                  Icons.access_time,
                  _formatDate(approval.decidedAt ?? approval.requestedAt),
                  Colors.grey,
                ),
              ],
            ),
            
            // Rejection reason if available
            if (approval.status == 'rejected' && approval.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rejection Reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      approval.rejectionReason!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryDetailItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showApprovalConfirmation(ApprovalRequest approval) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Registration'),
        content: Text(
          'Are you sure you want to approve ${approval.newUserName}\'s registration?\n\n'
          'They will be granted access to the TIRI platform.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authController.approveUser(approval.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(ApprovalRequest approval) {
    showDialog(
      context: context,
      builder: (context) => RejectionDialog(
        userName: approval.newUserName,
        userEmail: approval.newUserEmail,
        onCancel: () => Navigator.pop(context),
        onConfirm: (reason) {
          Navigator.pop(context);
          authController.rejectUser(approval.id, reason);
        },
      ),
    );
  }

  void _showApprovalDetails(ApprovalRequest approval) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          approval.newUserName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Details
              _buildDetailRow('Country', approval.newUserCountry, Icons.location_on),
              if (approval.newUserPhone != null)
                _buildDetailRow('Phone', approval.newUserPhone!, Icons.phone),
              _buildDetailRow('Referral Code', approval.referralCodeUsed, Icons.code),
              _buildDetailRow('Requested', _formatDate(approval.requestedAt), Icons.access_time),
              _buildDetailRow('Expires', _formatDate(approval.expiresAt), Icons.schedule),
              
              const SizedBox(height: 24),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showRejectionDialog(approval);
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showApprovalConfirmation(approval);
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
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