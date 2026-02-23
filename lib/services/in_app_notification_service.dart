import 'package:flutter/material.dart';
import 'notification_service.dart';

class InAppNotificationService implements NotificationService {
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  InAppNotificationService(this.messengerKey);

  @override
  void success(String message) {
    _show(message, Colors.green);
  }

  @override
  void error(String message) {
    _show(message, Colors.red);
  }

  @override
  void info(String message) {
    _show(message, Colors.blue);
  }

  void _show(String message, Color color) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
