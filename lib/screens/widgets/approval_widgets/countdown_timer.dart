import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final String label;
  final VoidCallback? onExpired;

  const CountdownTimer({
    Key? key,
    required this.endTime,
    this.label = 'Expires in',
    this.onExpired,
  }) : super(key: key);

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    if (widget.endTime.isAfter(now)) {
      setState(() {
        _timeRemaining = widget.endTime.difference(now);
      });
    } else {
      setState(() {
        _timeRemaining = Duration.zero;
      });
      _timer?.cancel();
      widget.onExpired?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeRemaining == Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Expired',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    String timeText;
    Color timeColor;

    if (days > 0) {
      timeText = '${widget.label} $days days, $hours hours';
      timeColor = days > 1 ? Colors.green : Colors.orange;
    } else if (hours > 0) {
      timeText = '${widget.label} $hours hours, $minutes minutes';
      timeColor = hours > 12 ? Colors.orange : Colors.red;
    } else if (minutes > 0) {
      timeText = '${widget.label} $minutes minutes, $seconds seconds';
      timeColor = Colors.red;
    } else {
      timeText = '${widget.label} $seconds seconds';
      timeColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: timeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: timeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, color: timeColor, size: 20),
          const SizedBox(width: 8),
          Text(
            timeText,
            style: TextStyle(
              color: timeColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}