import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../features/domain/entities/family_model.dart';
import '../../features/presentation/blocs/family/family_bloc.dart';
import '../../utils/popups/loaders.dart';
import '../widgets/empty/empty_widget.dart';
import '../widgets/error/error_widget.dart';

typedef FamilyDataBuilder = Widget Function(
  BuildContext context,
  FamilyModel? family,
);

class FamilyBuilder extends StatefulWidget {
  final bool autoLoad;
  final bool showErrorNotification;

  final void Function(FamilyModel? family)? onLoaded;
  final void Function(String error)? onError;

  /// Builder tổng (ưu tiên cao nhất)
  final FamilyDataBuilder? builder;

  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String message)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;

  const FamilyBuilder({
    super.key,
    this.autoLoad = true,
    this.showErrorNotification = true,
    this.onLoaded,
    this.onError,
    this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
  });

  @override
  State<FamilyBuilder> createState() => _FamilyBuilderState();
}

class _FamilyBuilderState extends State<FamilyBuilder> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  FamilyModel? _cachedFamily;

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      _loadFamily();
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _loadFamily() {
    context.read<FamilyBloc>().add(LoadFamilySubmitted());
  }

  Future<void> _onRefresh() async {
    _refreshController.resetNoData();
    context.read<FamilyBloc>().add(RefreshFamily());
  }

  Widget _buildLoading() {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context);
    }

    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError(String message) {
    return widget.errorBuilder?.call(context, message) ??
        TErrorWidget(
          message: message,
          onRetry: _loadFamily,
        );
  }

  Widget _buildEmpty() {
    if (widget.builder != null) {
      return widget.emptyBuilder?.call(context) ??
          const EmptyWidget(message: 'Bạn chưa có gia đình nào');
    }

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      enablePullDown: true,
      enablePullUp: false,
      child: widget.emptyBuilder?.call(context) ??
          const EmptyWidget(message: 'Bạn chưa có gia đình nào'),
    );
  }

  Widget _buildContent(FamilyModel? family) {
    if (family == null) return _buildEmpty();

    if (widget.builder != null) {
      return widget.builder!(context, family);
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FamilyBloc, FamilyState>(
      listener: (context, state) {
        switch (state) {
          case FamilyFailure(:final message):
            _refreshController.refreshFailed();
            if (widget.showErrorNotification) {
              TLoaders.showNotification(
                context,
                type: NotificationType.error,
                title: 'Lỗi',
                message: message,
              );
            }
            widget.onError?.call(message);

          case FamilyLoaded(:final family):
            _cachedFamily = family;
            _refreshController.refreshCompleted();
            widget.onLoaded?.call(family);

          case FamilyRefreshing(:final family):
            _cachedFamily = family;

          default:
            break;
        }
      },
      builder: (context, state) {
        // Lưu lại family data khi có
        if (state is FamilyLoaded) {
          _cachedFamily = state.family;
        } else if (state is FamilyRefreshing) {
          _cachedFamily = state.family;
        }

        return switch (state) {
          FamilyInitial() || FamilyLoading() => _buildLoading(),
          FamilyFailure(:final message) => _buildError(message),
          FamilyLoaded(:final family) => _buildContent(family),
          FamilyRefreshing(:final family) => _buildContent(family),
          // Với các analytics state, vẫn render content với family data đã cache
          _ => _cachedFamily != null
              ? _buildContent(_cachedFamily)
              : const SizedBox.shrink(),
        };
      },
    );
  }
}
