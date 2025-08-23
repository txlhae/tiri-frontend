import 'package:flutter/material.dart';
import 'package:tiri/models/auth_models.dart';
import 'package:tiri/services/account_status_service.dart';

/// Account Status Indicator Widget
/// 
/// Shows the current registration progress with visual step indicators.
/// Displays completed steps, current step, and pending steps.
class AccountStatusIndicator extends StatelessWidget {
  final RegistrationStage registrationStage;
  final bool showLabels;
  final bool showProgress;
  final EdgeInsets? padding;

  const AccountStatusIndicator({
    super.key,
    required this.registrationStage,
    this.showLabels = true,
    this.showProgress = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final accountStatusService = AccountStatusService.instance;
    final setupSteps = accountStatusService.getSetupSteps(registrationStage);
    final steps = setupSteps['all'] as List<Map<String, dynamic>>;
    final progress = accountStatusService.getSetupProgress(registrationStage);

    return Container(
      padding: padding ?? const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          if (showProgress) ...[
            Row(
              children: [
                const Text(
                  'Setup Progress',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(0, 140, 170, 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color.fromRGBO(0, 140, 170, 1),
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Step indicators
          Column(
            children: steps.map((step) {
              final index = steps.indexOf(step);
              final isCompleted = step['completed'] as bool;
              final isCurrent = step['current'] as bool;
              final isLast = index == steps.length - 1;

              return _buildStepIndicator(
                step: step,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isLast: isLast,
                showLabels: showLabels,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required Map<String, dynamic> step,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
    required bool showLabels,
  }) {
    Color iconColor;
    Color lineColor;
    IconData iconData;

    if (isCompleted) {
      iconColor = Colors.green.shade600;
      lineColor = Colors.green.shade300;
      iconData = Icons.check_circle;
    } else if (isCurrent) {
      iconColor = const Color.fromRGBO(0, 140, 170, 1);
      lineColor = Colors.grey.shade300;
      iconData = Icons.radio_button_unchecked;
    } else {
      iconColor = Colors.grey.shade400;
      lineColor = Colors.grey.shade300;
      iconData = Icons.radio_button_unchecked;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step icon and connector line
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? iconColor : Colors.white,
                border: Border.all(
                  color: iconColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                size: 16,
                color: isCompleted ? Colors.white : iconColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: lineColor,
              ),
          ],
        ),

        const SizedBox(width: 12),

        // Step content
        if (showLabels)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['label'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCompleted || isCurrent 
                        ? FontWeight.w600 
                        : FontWeight.w400,
                    color: isCompleted 
                        ? Colors.green.shade700
                        : isCurrent 
                            ? Colors.black87
                            : Colors.grey.shade600,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 4),
                  Text(
                    _getStepDescription(step['key'] as String),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                if (!isLast) const SizedBox(height: 16),
              ],
            ),
          ),
      ],
    );
  }

  String _getStepDescription(String stepKey) {
    switch (stepKey) {
      case 'email_verification':
        return 'Check your email and click the verification link';
      case 'approval':
        return 'Waiting for your referrer to approve your account';
      case 'complete':
        return 'Finalizing your account setup';
      default:
        return 'In progress...';
    }
  }
}

/// Compact version of account status indicator for use in app bars or small spaces
class CompactAccountStatusIndicator extends StatelessWidget {
  final RegistrationStage registrationStage;
  final VoidCallback? onTap;

  const CompactAccountStatusIndicator({
    super.key,
    required this.registrationStage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accountStatusService = AccountStatusService.instance;
    final progress = accountStatusService.getSetupProgress(registrationStage);
    final setupSteps = accountStatusService.getSetupSteps(registrationStage);
    final completed = (setupSteps['completed'] as List).length;
    final total = (setupSteps['all'] as List).length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color.fromRGBO(0, 140, 170, 1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color.fromRGBO(0, 140, 170, 1),
                    ),
                  ),
                ),
                Text(
                  '$completed',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(0, 140, 170, 1),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              '$completed of $total complete',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(0, 140, 170, 1),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Color.fromRGBO(0, 140, 170, 1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}