import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/domain/entities/analysis_model.dart';
import '../../features/presentation/blocs/analysis/analysis_bloc.dart';
import '../../utils/popups/loaders.dart';
import '../widgets/error/error_widget.dart';

typedef AnalysisDataBuilder = Widget Function(
  BuildContext context,
  AnalysisModel? analysis,
);

class AnalysisBuilder extends StatefulWidget {
  const AnalysisBuilder({
    super.key,
    this.includePeriodBreakdown,
    this.breakdownType,
    this.walletId,
    this.startDate,
    this.endDate,
    this.autoLoad = true,
    this.showErrorNotification = true,
    this.onLoaded,
    this.onError,
    this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final bool? includePeriodBreakdown;
  final String? breakdownType;
  final String? walletId;
  final DateTime? startDate;
  final DateTime? endDate;

  final bool autoLoad;
  final bool showErrorNotification;

  final void Function(AnalysisModel? analysis)? onLoaded;
  final void Function(String error)? onError;

  /// ✅ MAIN UI BUILDER
  final AnalysisDataBuilder? builder;

  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String message)? errorBuilder;

  @override
  State<AnalysisBuilder> createState() => AnalysisBuilderState();
}

class AnalysisBuilderState extends State<AnalysisBuilder> {
  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      _loadAnalysis();
    }
  }

  @override
  void didUpdateWidget(covariant AnalysisBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.includePeriodBreakdown != oldWidget.includePeriodBreakdown ||
        widget.breakdownType != oldWidget.breakdownType ||
        widget.walletId != oldWidget.walletId ||
        widget.startDate != oldWidget.startDate ||
        widget.endDate != oldWidget.endDate) {
      _loadAnalysis();
    }
  }

  void _loadAnalysis() {
    context.read<AnalysisBloc>().add(
          LoadAnalysisSubmitted(
            includePeriodBreakdown: widget.includePeriodBreakdown,
            breakdownType: widget.breakdownType,
            walletId: widget.walletId,
            startDate: widget.startDate,
            endDate: widget.endDate,
          ),
        );
  }

  /// Public method để refresh lại với đúng params ban đầu
  void refresh() {
    context.read<AnalysisBloc>().add(
          RefreshAnalysis(
            includePeriodBreakdown: widget.includePeriodBreakdown,
            breakdownType: widget.breakdownType,
            walletId: widget.walletId,
            startDate: widget.startDate,
            endDate: widget.endDate,
          ),
        );
  }

  Widget _buildLoading() =>
      widget.loadingBuilder?.call(context) ?? const SizedBox.shrink();

  Widget _buildError(String message) =>
      widget.errorBuilder?.call(context, message) ??
      TErrorWidget(
        message: message,
        onRetry: _loadAnalysis,
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AnalysisBloc, AnalysisState>(
      listener: (context, state) {
        switch (state) {
          case AnalysisFailure(:final message):
            if (widget.showErrorNotification) {
              TLoaders.showNotification(
                context,
                type: NotificationType.error,
                title: 'Lỗi',
                message: message,
              );
            }
            widget.onError?.call(message);

          case AnalysisLoaded(:final analysis):
            widget.onLoaded?.call(analysis);

          default:
            break;
        }
      },
      builder: (context, state) => switch (state) {
        AnalysisInitial() || AnalysisLoading() => _buildLoading(),
        AnalysisFailure(:final message) => _buildError(message),
        AnalysisLoaded(:final analysis) =>
            widget.builder?.call(context, analysis) ?? const SizedBox.shrink(),
        AnalysisRefreshing(:final analysis) =>
            widget.builder?.call(context, analysis) ?? const SizedBox.shrink(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
