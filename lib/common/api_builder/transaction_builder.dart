import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../features/domain/entities/transaction_model.dart';
import '../../features/presentation/blocs/transaction/transaction_bloc.dart';
import '../../features/presentation/blocs/budget/budget_bloc.dart';
import '../../features/presentation/blocs/wallet/wallet_bloc.dart';
import '../../utils/loaders/transaction_card_loading.dart';
import '../../utils/popups/loaders.dart';
import '../widgets/card/transaction_card.dart';
import '../widgets/empty/empty_widget.dart';
import '../widgets/error/error_widget.dart';

typedef TransactionDataBuilder = Widget Function(
  BuildContext context,
  List<TransactionModel> transactions,
);

class TransactionBuilder extends StatefulWidget {
  final String? type;

  final int? page;

  final int? limit;

  final DateTime? month;

  final String? walletId;

  final bool autoLoad;

  final bool showErrorNotification;

  final void Function(List<TransactionModel> transactions)? onLoaded;

  final void Function(String error)? onError;
  final void Function()? onRefresh;

  final TransactionDataBuilder? builder;

  final Widget Function(BuildContext context)? loadingBuilder;

  final Widget Function(BuildContext context, String message)? errorBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;

  /// ✅ fallback item builder (grouped by date)
  final Widget Function(
    BuildContext context,
    DateTime date,
    List<TransactionModel> transactions,
    double totalExpense,
  )? itemBuilder;

  final double Function(List<TransactionModel> transactions)?
      calculateTotalExpense;

  /// Tắt SmartRefresher khi được đặt trong scrollable context (như SingleChildScrollView)
  final bool disableScroll;

  const TransactionBuilder({
    super.key,
    this.type,
    this.page = 1,
    this.limit = 20,
    this.month,
    this.walletId,
    this.autoLoad = true,
    this.showErrorNotification = true,
    this.onLoaded,
    this.onError,
    this.onRefresh,
    this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.itemBuilder,
    this.calculateTotalExpense,
    this.disableScroll = false,
  });

  @override
  State<TransactionBuilder> createState() => _TransactionBuilderState();
}

class _TransactionBuilderState extends State<TransactionBuilder> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  int _currentPage = 1;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.page ?? 1;
    if (widget.autoLoad) {
      _loadTransactions(reset: true);
    }
  }

  @override
  void didUpdateWidget(covariant TransactionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type != oldWidget.type ||
        widget.limit != oldWidget.limit ||
        widget.month != oldWidget.month ||
        widget.walletId != oldWidget.walletId) {
      _loadTransactions(reset: true);
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _loadTransactions({bool reset = false}) {
    if (reset) _currentPage = widget.page ?? 1;

    context.read<TransactionBloc>().add(
          LoadTransactionsSubmitted(
            type: widget.type,
            page: _currentPage,
            limit: widget.limit,
            month: widget.month,
            walletId: widget.walletId,
          ),
        );
  }

  Future<void> _onRefresh() async {
    _refreshController.resetNoData();
    _currentPage = 1;
    _isRefreshing = true;

    context.read<TransactionBloc>().add(
          RefreshTransactions(
            type: widget.type,
            page: _currentPage,
            limit: widget.limit,
            month: widget.month,
            walletId: widget.walletId,
          ),
        );
  }

  void _onLoadMore() {
    final state = context.read<TransactionBloc>().state;
    if (state is TransactionLoaded && state.hasMore) {
      _currentPage++;
      context.read<TransactionBloc>().add(
            LoadMoreTransactions(
              type: widget.type,
              page: _currentPage,
              limit: widget.limit,
              month: widget.month,
              walletId: widget.walletId,
            ),
          );
    } else {
      _refreshController.loadNoData();
    }
  }

  double _defaultCalculateTotalExpense(List<TransactionModel> transactions) {
    return transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + (t.amount ?? 0));
  }

  Widget _buildLoading() =>
      widget.loadingBuilder?.call(context) ?? const TransactionCardLoading();

  Widget _buildError(String message) =>
      widget.errorBuilder?.call(context, message) ??
      TErrorWidget(
        message: message,
        onRetry: () => _loadTransactions(reset: true),
      );

  Widget _buildEmpty() {
    final emptyWidget = widget.emptyBuilder?.call(context) ?? const EmptyWidget();
    if (widget.disableScroll) {
      return emptyWidget;
    }
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      enablePullDown: true,
      enablePullUp: false,
      child: emptyWidget,
    );
  }

  /// ✅ SINGLE SOURCE OF TRUTH
  Widget _buildList(
    List<TransactionModel> transactions,
    bool hasMore, {
    bool isLoadingMore = false,
  }) {
    if (transactions.isEmpty) return _buildEmpty();

    final content = widget.builder != null
        ? widget.builder!(context, transactions)
        : _defaultGroupedList(
            transactions,
            isLoadingMore: isLoadingMore,
          );

    if (widget.disableScroll) {
      return content;
    }

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoadMore,
      enablePullDown: true,
      enablePullUp: hasMore,
      child: content,
    );
  }

  /// ✅ DEFAULT GROUPED LIST (fallback)
  Widget _defaultGroupedList(
    List<TransactionModel> transactions, {
    bool isLoadingMore = false,
  }) {
    final grouped = <DateTime, List<TransactionModel>>{};
    for (final t in transactions) {
      if (t.date == null) continue;
      final day = DateTime(t.date!.year, t.date!.month, t.date!.day);
      grouped.putIfAbsent(day, () => []).add(t);
    }

    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final calculateTotal =
        widget.calculateTotalExpense ?? _defaultCalculateTotalExpense;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: dates.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (isLoadingMore && index == dates.length) {
          return const Skeletonizer(
            enabled: true,
            child: TransactionCardLoading(),
          );
        }

        final date = dates[index];
        final dayTransactions = grouped[date]!;
        final total = calculateTotal(dayTransactions);

        return widget.itemBuilder != null
            ? widget.itemBuilder!(
                context,
                date,
                dayTransactions,
                total,
              )
            : TransactionCard(
                date: date,
                transactions: dayTransactions,
                totalExpense: total,
              );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionBloc, TransactionState>(
      listener: (context, state) {
        switch (state) {
          case TransactionFailure(:final message):
            _refreshController.refreshFailed();
            _refreshController.loadFailed();
            if (widget.showErrorNotification) {
              TLoaders.showNotification(
                context,
                type: NotificationType.error,
                title: 'Lỗi',
                message: message,
              );
            }
            widget.onError?.call(message);

          case TransactionLoaded(:final currentPage, :final hasMore):
            _currentPage = currentPage;
            currentPage == 1
                ? _refreshController.refreshCompleted()
                : hasMore
                    ? _refreshController.loadComplete()
                    : _refreshController.loadNoData();
            widget.onLoaded?.call(state.transactions);
            // Chỉ gọi onRefresh khi thực sự là refresh (không phải load lần đầu hoặc load more)
            if (_isRefreshing && currentPage == 1) {
              widget.onRefresh?.call();
              _isRefreshing = false;
            }

          case TransactionDeleted():
            TLoaders.showNotification(
              context,
              type: NotificationType.success,
              title: 'Thành công',
              message: 'Xóa giao dịch thành công',
            );
            // Refresh danh sách
            _loadTransactions(reset: true);
            // Refresh AnalysisBuilder để cập nhật tổng quan
            widget.onRefresh?.call();
            // Refresh wallet
            context.read<WalletBloc>().add(RefreshWallets());
            // Refresh budget
            context.read<BudgetBloc>().add(RefreshBudgets());

          case TransactionDeleteFailure(:final message):
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
        TransactionInitial() || TransactionLoading() => _buildLoading(),
        TransactionFailure(:final message) => _buildError(message),
        TransactionLoaded(:final transactions, :final hasMore) =>
          _buildList(transactions, hasMore),
        TransactionRefreshing(:final transactions) =>
          _buildList(transactions, true),
        TransactionLoadingMore(:final transactions) =>
          _buildList(transactions, true, isLoadingMore: true),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
