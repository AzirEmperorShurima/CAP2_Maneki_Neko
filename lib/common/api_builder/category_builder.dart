import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/domain/entities/category_model.dart';
import '../../features/presentation/blocs/category/category_bloc.dart';
import '../../utils/loaders/category_loading.dart';
import '../../utils/popups/loaders.dart';
import '../widgets/error/error_widget.dart';

typedef CategoryDataBuilder = Widget Function(
  BuildContext context,
  List<CategoryModel> categories,
);

class CategoryBuilder extends StatefulWidget {
  const CategoryBuilder({
    super.key,
    required this.type,
    this.autoLoad = true,
    this.showErrorNotification = true,
    this.onLoaded,
    this.onError,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
  });

  final String? type;
  final bool autoLoad;
  final bool showErrorNotification;

  final void Function(List<CategoryModel> categories)? onLoaded;
  final void Function(String error)? onError;

  /// ✅ MAIN UI BUILDER - REQUIRED
  final CategoryDataBuilder builder;

  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String message, VoidCallback onRetry)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;

  @override
  State<CategoryBuilder> createState() => CategoryBuilderState();
}

class CategoryBuilderState extends State<CategoryBuilder> {

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad && widget.type != null) {
      _loadCategories();
    }
  }

  @override
  void didUpdateWidget(covariant CategoryBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type != oldWidget.type && widget.autoLoad && widget.type != null) {
      _loadCategories();
    }
  }

  void _loadCategories() {
    context.read<CategoryBloc>().add(
          LoadCategoriesSubmitted(type: widget.type),
        );
  }

  /// Public method để refresh lại với đúng params ban đầu
  void refresh() {
    if (widget.type != null) {
      context.read<CategoryBloc>().add(
            LoadCategoriesSubmitted(type: widget.type),
          );
    }
  }

  Widget _buildLoading() =>
      widget.loadingBuilder?.call(context) ?? const CategoryGridLoading();

  Widget _buildError(String message) =>
      widget.errorBuilder?.call(context, message, _loadCategories) ??
      TErrorWidget(
        height: 200,
        message: message,
        onRetry: _loadCategories,
      );

  Widget _buildEmpty() =>
      widget.emptyBuilder?.call(context) ??
      const Center(
        child: Text('Không có danh mục nào'),
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, state) {
        switch (state) {
          case CategoryFailure(:final message):
            if (widget.showErrorNotification) {
              TLoaders.showNotification(
                context,
                type: NotificationType.error,
                title: 'Lỗi',
                message: message,
              );
            }
            widget.onError?.call(message);

          case CategoryLoaded(:final categories):
            widget.onLoaded?.call(categories);

          default:
            break;
        }
      },
      builder: (context, state) => switch (state) {
        CategoryInitial() || CategoryLoading() => _buildLoading(),
        CategoryFailure(:final message) => _buildError(message),
        CategoryLoaded(:final categories) => categories.isEmpty
            ? _buildEmpty()
            : widget.builder(context, categories),
        _ => const Center(
            child: Text('Vui lòng chọn loại giao dịch'),
          ),
      },
    );
  }
}
