import 'package:flutter/material.dart';

import '../../../features/domain/entities/category_model.dart';
import '../../../utils/helpers/category_icon_helper.dart';

/// Widget hiển thị icon của category
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.transactionType,
    this.size = 40,
    this.fit = BoxFit.contain,
  });

  /// Category model chứa thông tin category
  final CategoryModel? category;

  /// Type của transaction (expense/income) - nếu null sẽ dùng category.type
  final String? transactionType;

  /// Kích thước icon
  final double size;

  /// BoxFit cho image
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final categoryName = category?.name;
    final type = transactionType ?? category?.type;

    final iconPath = CategoryIconHelper.getIconPath(categoryName, type);

    return Image.asset(
      iconPath,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback nếu icon không tồn tại
        return Image.asset(
          CategoryIconHelper.defaultIcon,
          width: size,
          height: size,
          fit: fit,
        );
      },
    );
  }
}

