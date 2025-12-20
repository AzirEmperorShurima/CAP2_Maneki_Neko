import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/domain/entities/wallet_analysis_model.dart';
import '../../features/presentation/blocs/wallet_analysis/wallet_analysis_bloc.dart';
import '../../utils/popups/loaders.dart';
import '../widgets/error/error_widget.dart';

typedef WalletAnalysisDataBuilder = Widget Function(
  BuildContext context,
  WalletAnalysisModel? analysis,
);

class WalletAnalysisBuilder extends StatefulWidget {
  const WalletAnalysisBuilder({
    super.key,
    required this.walletId,
    this.autoLoad = true,
    this.showErrorNotification = true,
    this.onLoaded,
    this.onError,
    this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String walletId;

  final bool autoLoad;
  final bool showErrorNotification;

  final void Function(WalletAnalysisModel? analysis)? onLoaded;
  final void Function(String error)? onError;

  /// ✅ MAIN UI BUILDER
  final WalletAnalysisDataBuilder? builder;

  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String message)? errorBuilder;

  @override
  State<WalletAnalysisBuilder> createState() => WalletAnalysisBuilderState();
}

class WalletAnalysisBuilderState extends State<WalletAnalysisBuilder> {
  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      _loadAnalysis();
    }
  }

  @override
  void didUpdateWidget(covariant WalletAnalysisBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.walletId != oldWidget.walletId) {
      _loadAnalysis();
    }
  }

  void _loadAnalysis() {
    context.read<WalletAnalysisBloc>().add(
          LoadWalletAnalysisSubmitted(walletId: widget.walletId),
        );
  }

  /// Public method để refresh lại với đúng params ban đầu
  void refresh() {
    context.read<WalletAnalysisBloc>().add(
          RefreshWalletAnalysis(walletId: widget.walletId),
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
    return BlocConsumer<WalletAnalysisBloc, WalletAnalysisState>(
      listener: (context, state) {
        switch (state) {
          case WalletAnalysisFailure(:final message):
            if (widget.showErrorNotification) {
              TLoaders.showNotification(
                context,
                type: NotificationType.error,
                title: 'Lỗi',
                message: message,
              );
            }
            widget.onError?.call(message);

          case WalletAnalysisLoaded(:final analysis):
            widget.onLoaded?.call(analysis);

          default:
            break;
        }
      },
      builder: (context, state) => switch (state) {
        WalletAnalysisInitial() || WalletAnalysisLoading() => _buildLoading(),
        WalletAnalysisFailure(:final message) => _buildError(message),
        WalletAnalysisLoaded(:final analysis) =>
            widget.builder?.call(context, analysis) ?? const SizedBox.shrink(),
        WalletAnalysisRefreshing(:final analysis) =>
            widget.builder?.call(context, analysis) ?? const SizedBox.shrink(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
