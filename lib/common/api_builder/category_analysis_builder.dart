import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/domain/entities/category_analysis_model.dart';
import '../../features/presentation/blocs/category_analysis/category_analysis_bloc.dart';
import '../../utils/popups/loaders.dart';
import '../widgets/error/error_widget.dart';

typedef CategoryAnalysisDataBuilder = Widget Function(
  BuildContext context,
  CategoryAnalysisModel? analysis,
);

class CategoryAnalysisBuilder extends StatefulWidget {
  const CategoryAnalysisBuilder({
    super.key,
    this.type,
    this.autoLoad = true,
    this.showErrorNotification = true,
    this.onLoaded,
    this.onError,
    this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String? type;
  final bool autoLoad;
  final bool showErrorNotification;

  final void Function(CategoryAnalysisModel? analysis)? onLoaded;
  final void Function(String error)? onError;

  final CategoryAnalysisDataBuilder? builder;

  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String message)? errorBuilder;

  @override
  State<CategoryAnalysisBuilder> createState() => _CategoryAnalysisBuilderState();
}

class _CategoryAnalysisBuilderState extends State<CategoryAnalysisBuilder> {
  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      _loadCategoryAnalysis();
    }
  }

  @override
  void didUpdateWidget(covariant CategoryAnalysisBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type != oldWidget.type) {
      _loadCategoryAnalysis();
    }
  }

  void _loadCategoryAnalysis() {
    context.read<CategoryAnalysisBloc>().add(
          LoadCategoryAnalysisSubmitted(type: widget.type),
        );
  }

  Widget _buildLoading() =>
      widget.loadingBuilder?.call(context) ?? const SizedBox.shrink();

  Widget _buildError(String message) =>
      widget.errorBuilder?.call(context, message) ??
      TErrorWidget(
        message: message,
        onRetry: _loadCategoryAnalysis,
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryAnalysisBloc, CategoryAnalysisState>(
      listener: (context, state) {
        switch (state) {
          case CategoryAnalysisFailure(:final message):
            if (widget.showErrorNotification) {
              TLoaders.showNotification(
                context,
                type: NotificationType.error,
                title: 'Lỗi',
                message: message,
              );
            }
            widget.onError?.call(message);

          case CategoryAnalysisLoaded(:final analysis):
            widget.onLoaded?.call(analysis);

          default:
            break;
        }
      },
      builder: (context, state) => switch (state) {
        CategoryAnalysisInitial() || CategoryAnalysisLoading() => _buildLoading(),
        CategoryAnalysisFailure(:final message) => _buildError(message),
        CategoryAnalysisLoaded(:final analysis) =>
            widget.builder?.call(context, analysis) ?? const SizedBox.shrink(),
        CategoryAnalysisRefreshing(:final analysis) =>
            widget.builder?.call(context, analysis) ?? const SizedBox.shrink(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
