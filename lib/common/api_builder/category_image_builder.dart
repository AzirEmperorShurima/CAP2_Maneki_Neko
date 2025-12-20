import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/domain/entities/category_image_model.dart';
import '../../features/presentation/blocs/category/category_bloc.dart';
import '../../utils/popups/loaders.dart';
import '../widgets/error/error_widget.dart';

typedef CategoryImageDataBuilder = Widget Function(
  BuildContext context,
  List<CategoryImageModel> images,
);

class CategoryImageBuilder extends StatefulWidget {
  const CategoryImageBuilder({
    super.key,
    this.folder,
    this.limit,
    this.cursor,
    this.autoLoad = true,
    this.showErrorNotification = true,
    this.onLoaded,
    this.onError,
    this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String? folder;
  final int? limit;
  final String? cursor;
  final bool autoLoad;
  final bool showErrorNotification;

  final void Function(List<CategoryImageModel> images)? onLoaded;
  final void Function(String error)? onError;

  final CategoryImageDataBuilder? builder;

  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String message)? errorBuilder;

  @override
  State<CategoryImageBuilder> createState() => _CategoryImageBuilderState();
}

class _CategoryImageBuilderState extends State<CategoryImageBuilder> {
  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      _loadImages();
    }
  }

  @override
  void didUpdateWidget(covariant CategoryImageBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.folder != oldWidget.folder ||
        widget.limit != oldWidget.limit ||
        widget.cursor != oldWidget.cursor) {
      _loadImages();
    }
  }

  void _loadImages() {
    context.read<CategoryBloc>().add(
          LoadCategoryImagesSubmitted(
            folder: widget.folder,
            limit: widget.limit,
            cursor: widget.cursor,
          ),
        );
  }

  Widget _buildLoading() =>
      widget.loadingBuilder?.call(context) ?? const Center(
        child: CircularProgressIndicator(),
      );

  Widget _buildError(String message) =>
      widget.errorBuilder?.call(context, message) ??
      TErrorWidget(
        message: message,
        onRetry: _loadImages,
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, state) {
        switch (state) {
          case CategoryImagesFailure(:final message):
            if (widget.showErrorNotification) {
              TLoaders.showNotification(
                context,
                type: NotificationType.error,
                title: 'Lỗi',
                message: message,
              );
            }
            widget.onError?.call(message);

          case CategoryImagesLoaded(:final images):
            widget.onLoaded?.call(images);

          default:
            break;
        }
      },
      builder: (context, state) => switch (state) {
        CategoryImagesLoading() => _buildLoading(),
        CategoryImagesFailure(:final message) => _buildError(message),
        CategoryImagesLoaded(:final images) =>
            widget.builder?.call(context, images) ?? const SizedBox.shrink(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

