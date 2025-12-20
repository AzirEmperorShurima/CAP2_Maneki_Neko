import 'package:flutter/material.dart';

import '../../../constants/assets.dart';
import '../../../constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../../utils/loaders/animation_loader.dart';

class TErrorWidget extends StatelessWidget {
  final String? message;
  
  final VoidCallback? onRetry;

  final double? height;

  const TErrorWidget({
    super.key,
    this.message,
    this.onRetry,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TAnimationLoaderWidget(
        text: message ?? 'Có lỗi xảy ra, vui lòng thử lại sau',
        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.darkGrey),
        animation: Assets.animationCatError,
        width: THelperFunctions.screenWidth(context),
        height: height ?? 300,
        showAction: onRetry != null,
        actionText: 'Thử lại',
        onActionPressed: onRetry,
      ),
    );
  }
}

