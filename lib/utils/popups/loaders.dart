import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

enum NotificationType { success, warning, error }

class TLoaders {
  static showNotification(
    BuildContext context, {
    required NotificationType type,
    required String title,
    String? message,
  }) {
    switch (type) {
      case NotificationType.success:
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 2),
          title: Text(title),
          description: RichText(text: TextSpan(text: message)),
          alignment: Alignment.bottomCenter,
          direction: TextDirection.ltr,
        );
        break;
      case NotificationType.warning:
        toastification.show(
          context: context,
          type: ToastificationType.warning,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 2),
          title: Text(title),
          description: RichText(text: TextSpan(text: message)),
          alignment: Alignment.bottomCenter,
          direction: TextDirection.ltr,
        );
        break;
      case NotificationType.error:
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 2),
          title: Text(title),
          description: RichText(text: TextSpan(text: message)),
          alignment: Alignment.bottomCenter,
          direction: TextDirection.ltr,
        );
        break;
    }
  }
}
