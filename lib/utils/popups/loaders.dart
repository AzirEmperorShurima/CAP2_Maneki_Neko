import 'package:finance_management_app/constants/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../constants/app_border_radius.dart';

enum NotificationType { info, success, warning, error }

class TLoaders {
  static showNotification(
    BuildContext context, {
    required NotificationType type,
    required String title,
    required String message,
    int? timeDuration,
  }) {
    switch (type) {
      case NotificationType.info:
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: Duration(seconds: timeDuration ?? 2),
          title: Text(title),
          description: RichText(text: TextSpan(text: message)),
          alignment: Alignment.bottomCenter,
          direction: TextDirection.ltr,
        );
        break;
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
          autoCloseDuration: Duration(seconds: timeDuration ?? 2),
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
          autoCloseDuration: Duration(seconds: timeDuration ?? 2),
          title: Text(title),
          description: RichText(text: TextSpan(text: message)),
          alignment: Alignment.bottomCenter,
          direction: TextDirection.ltr,
        );
        break;
    }
  }

  static Future<bool> showConfirmActionSheet({
    required BuildContext context,
    required String title,
    String? message,
    Widget? messageWidget,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
    Color? cancelColor,
    Future<void> Function()? onConfirm,
    Future<void> Function()? onCancel,
  }) async {
    bool isConfirmed = false;

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoTheme(
        data: CupertinoTheme.of(context).copyWith(
          scaffoldBackgroundColor: Colors.white,
          barBackgroundColor: Colors.white,
        ),
        child: CupertinoActionSheet(
          actions: <Widget>[
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            decoration: TextDecoration.none,
                            fontFamily: 'Roboto',
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (message != null || messageWidget != null) ...[
                      const SizedBox(height: 8),
                      messageWidget ??
                          Text(
                            message!,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  decoration: TextDecoration.none,
                                  fontFamily: 'Roboto',
                                ),
                            textAlign: TextAlign.center,
                          ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () async {
                  isConfirmed = true;
                  if (onConfirm != null) {
                    await onConfirm();
                  }
                },
                child: Text(
                  confirmText ?? 'Xác nhận',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: confirmColor ?? TColors.error,
                        decoration: TextDecoration.none,
                      ),
                ),
              ),
            ),
          ],
          cancelButton: Container(
            decoration: const BoxDecoration(
              borderRadius: AppBorderRadius.md,
              color: Colors.white,
            ),
            child: CupertinoActionSheetAction(
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              child: Text(
                cancelText ?? 'Cancel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cancelColor ?? TColors.primary,
                      decoration: TextDecoration.none,
                    ),
              ),
            ),
          ),
        ),
      ),
    );

    return isConfirmed;
  }

  static Future<T?> bottomSheet<T>({
    required BuildContext context,
    required Widget child,
    Color? backgroundColor,
    String? barrierLabel,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool isScrollControlled = false,
    bool useRootNavigator = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool? showDragHandle,
    bool useSafeArea = false,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
    Offset? anchorPoint,
    AnimationStyle? sheetAnimationStyle,
    BorderRadiusGeometry? borderRadius,
    bool avoidKeyboard = false,
    bool useRouteName = false,
    double? heightPercentage, // 0.6 for 60%, 0.7 for 70%, 0.8 for 80%
  }) {
    return showModalBottomSheet(
      backgroundColor: backgroundColor ?? TColors.white,
      isDismissible: isDismissible,
      context: context,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: useRouteName
          ? RouteSettings(
              name: 'APP_DIALOG_${DateTime.now().millisecondsSinceEpoch}',
            )
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? AppBorderRadius.xlTop,
      ),
      isScrollControlled: isScrollControlled || heightPercentage != null,
      clipBehavior: Clip.antiAlias,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final maxHeight =
            heightPercentage != null ? screenHeight * heightPercentage : null;

        if (avoidKeyboard) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            body: SizedBox(
              height: maxHeight,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: SafeArea(child: child)),
                  ]),
            ),
          );
        }

        return SizedBox(
          height: maxHeight,
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(child: SafeArea(child: child)),
                ]),
          ),
        );
      },
    );
  }
}
