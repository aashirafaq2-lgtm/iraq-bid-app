import 'package:flutter/material.dart';
import 'dart:async';

enum CountdownSize { small, medium, large }

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final CountdownSize size;

  const CountdownTimer({
    super.key,
    required this.endTime,
    this.size = CountdownSize.medium,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimer() {
    final now = DateTime.now();
    final difference = widget.endTime.difference(now);

    if (difference.isNegative) {
      setState(() {
        _remaining = Duration.zero;
      });
      _timer?.cancel();
    } else {
      setState(() {
        _remaining = difference;
      });
    }
  }

  // BarezBid Color Palette
  static const Color _timerColor = Color(0xFFFF5555);
  static const Color _timerBg = Color(0xFFFF5555);
  static const Color _timerText = Color(0xFFFFFFFF);

  Color _getColor() {
    // Always use BarezBid timer color
    return _timerText; // White text on red background
  }

  Color _getBackgroundColor(BuildContext context) {
    // Always use red background for timer
    return _timerBg;
  }

  double _getFontSize() {
    switch (widget.size) {
      case CountdownSize.small:
        return 10;
      case CountdownSize.medium:
        return 12;
      case CountdownSize.large:
        return 14;
    }
  }

  double _getPadding() {
    switch (widget.size) {
      case CountdownSize.small:
        return 8;
      case CountdownSize.medium:
        return 12;
      case CountdownSize.large:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative || _remaining.inSeconds <= 0) {
      return Container(
        padding: EdgeInsets.all(_getPadding()),
        decoration: BoxDecoration(
          color: _timerBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 12, color: _timerText),
            const SizedBox(width: 4),
            Text(
              'Ended',
              style: TextStyle(
                fontSize: _getFontSize(),
                color: _timerText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    String timeText = '';
    if (days > 0) {
      timeText += '${days}d ';
    }
    timeText += '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getPadding(),
        vertical: _getPadding() / 2,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 12,
            color: _getColor(),
          ),
          const SizedBox(width: 6),
          Text(
            timeText,
            style: TextStyle(
              fontSize: _getFontSize(),
              fontWeight: FontWeight.bold,
              color: _getColor(),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

