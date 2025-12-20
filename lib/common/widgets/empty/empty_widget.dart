import 'package:flutter/material.dart';

import '../../../constants/assets.dart';
import '../../../constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../../../utils/loaders/animation_loader.dart';

/// Widget hiển thị khi danh sách rỗng
class EmptyWidget extends StatelessWidget {
  const EmptyWidget({
    super.key,
    this.message,
    this.onRefresh,
  });

  /// Thông báo hiển thị khi rỗng
  final String? message;

  /// Callback khi pull to refresh
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TAnimationLoaderWidget(
        text: message ?? 'Bạn chưa có giao dịch nào',
        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.darkGrey),
        animation: Assets.animationCatError,
        width: THelperFunctions.screenWidth(context),
        height: 300,
      ),
    );
  }
}

