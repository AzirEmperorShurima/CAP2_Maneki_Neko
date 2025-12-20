import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../features/domain/entities/budget_model.dart';
import '../../features/presentation/blocs/budget/budget_bloc.dart';
import '../../utils/loaders/budget_card_loading.dart';
import '../../utils/popups/loaders.dart';
import '../widgets/empty/empty_widget.dart';
import '../widgets/error/error_widget.dart';

typedef BudgetDataBuilder = Widget Function(
  BuildContext context,
  List<BudgetModel> budgets,
);

class BudgetBuilder extends StatefulWidget {
  final bool autoLoad;
  final bool showErrorNotification;

  final void Function(List<BudgetModel> budgets)? onLoaded;
  final void Function(String error)? onError;

  /// Builder tổng (ưu tiên cao nhất)
  final BudgetDataBuilder? builder;

  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String message)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Builder từng item (fallback)
  final Widget Function(
    BuildContext context,
    BudgetModel budget,
    int index,
  )? itemBuilder;
  
  const BudgetBuilder({
    super.key,
    this.autoLoad = true,
    this.showErrorNotification = true,
    this.onLoaded,
    this.onError,
    this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.itemBuilder,
  });

  @override
  State<BudgetBuilder> createState() => _BudgetBuilderState();
}

class _BudgetBuilderState extends State<BudgetBuilder> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      _loadBudgets();
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _loadBudgets() {
    context.read<BudgetBloc>().add(LoadBudgetsSubmitted());
  }

  Future<void> _onRefresh() async {
    _refreshController.resetNoData();
    context.read<BudgetBloc>().add(RefreshBudgets());
  }

  Widget _buildLoading() {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context);
    }
    
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: 1,
        itemBuilder: (_, __) => const BudgetCardLoading(),
      ),
    );
  }

  Widget _buildError(String message) {
    return widget.errorBuilder?.call(context, message) ??
        TErrorWidget(
          message: message,
          onRetry: _loadBudgets,
        );
  }

  Widget _buildEmpty() {
    // Nếu có custom builder, không dùng SmartRefresher (vì sẽ được đặt trong SliverToBoxAdapter)
    if (widget.builder != null) {
      return widget.emptyBuilder?.call(context) ??
          const EmptyWidget(message: 'Bạn chưa có ngân sách nào');
    }
    
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      enablePullDown: true,
      enablePullUp: false,
      child: widget.emptyBuilder?.call(context) ??
          const EmptyWidget(message: 'Bạn chưa có ngân sách nào'),
    );
  }

  /// ✅ TRUNG TÂM QUYẾT ĐỊNH UI
  Widget _buildList(List<BudgetModel> budgets) {
    if (budgets.isEmpty) return _buildEmpty();

    // Nếu có custom builder, trả về trực tiếp (không wrap SmartRefresher)
    if (widget.builder != null) {
      return widget.builder!(context, budgets);
    }

    // Fallback: dùng SmartRefresher cho default list
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      enablePullDown: true,
      enablePullUp: false,
      child: _buildBudgetList(budgets),
    );
  }

  Widget _buildBudgetList(List<BudgetModel> budgets) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];

        return widget.itemBuilder != null
            ? widget.itemBuilder!(context, budget, index)
            : const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BudgetBloc, BudgetState>(
      listener: (context, state) {
        switch (state) {
          case BudgetFailure(:final message):
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

          case BudgetLoaded(:final budgets):
            _refreshController.refreshCompleted();
            widget.onLoaded?.call(budgets);

          case BudgetDeleted():
            TLoaders.showNotification(
              context,
              type: NotificationType.success,
              title: 'Thành công',
              message: 'Xóa ngân sách thành công',
            );
            // Refresh danh sách
            _loadBudgets();

          case BudgetDeleteFailure(:final message):
            if (widget.showErrorNotification) {
              TLoaders.showNotification(
                context,
                type: NotificationType.error,
                title: 'Lỗi',
                message: message,
              );
            }
            widget.onError?.call(message);

          case BudgetUpdated():
            TLoaders.showNotification(
              context,
              type: NotificationType.success,
              title: 'Thành công',
              message: 'Cập nhật ngân sách thành công',
            );
            // Refresh danh sách
            _loadBudgets();

          case BudgetUpdateFailure(:final message):
            if (widget.showErrorNotification) {
              TLoaders.showNotification(
                context,
                type: NotificationType.error,
                title: 'Lỗi',
                message: message,
              );
            }
            widget.onError?.call(message);

          default:
            break;
        }
      },
      builder: (context, state) => switch (state) {
        BudgetInitial() || BudgetLoading() => _buildLoading(),
        BudgetFailure(:final message) => _buildError(message),
        BudgetLoaded(:final budgets) => _buildList(budgets),
        BudgetRefreshing(:final budgets) => _buildList(budgets),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
