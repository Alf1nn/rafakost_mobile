// lib/widgets/tracking_gesture_detector.dart
import 'package:flutter/material.dart';
import '../services/remote_controller.dart';

class TrackingGestureDetector extends StatelessWidget {
  final Widget child;
  final String widgetName;
  final Map<String, dynamic>? extraData;
  
  const TrackingGestureDetector({
    super.key,
    required this.child,
    required this.widgetName,
    this.extraData,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        RemoteController.logTap(widgetName, extraData?.toString());
      },
      onLongPress: () {
        RemoteController.logTap("$widgetName (long press)", extraData?.toString());
      },
      child: child,
    );
  }
}