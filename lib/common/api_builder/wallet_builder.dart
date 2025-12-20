import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../features/domain/entities/wallet_model.dart';
import '../../features/presentation/blocs/wallet/wallet_bloc.dart';
import '../../utils/loaders/wallet_card_loading.dart';
import '../../utils/popups/loaders.dart';
import '../widgets/card/wallet_card.dart';
import '../widgets/empty/empty_widget.dart';
import '../widgets/error/error_widget.dart';

typedef WalletDataBuilder = Widget Function(
  BuildContext context,
  List<WalletModel> wallets,
);

class WalletBuilder extends StatefulWidget {

  final bool autoLoad;
  final bool showErrorNotification;

  final void Function(List<WalletModel> wallets)? onLoaded;
  final void Function(String error)? onError;
  final void Function()? onRefresh;

  /// Builder tổng (ưu tiên cao nhất)
  final WalletDataBuilder? builder;

  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String message)? errorBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Builder từng item (fallback)
  final Widget Function(
    BuildContext context,
    WalletModel wallet,
    int index,
  )? itemBuilder;
  
  const WalletBuilder({
    super.key,
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
  });

  @override
  State<WalletBuilder> createState() => _WalletBuilderState();
}

class _WalletBuilderState extends State<WalletBuilder> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      _loadWallets();
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _loadWallets() {
    context.read<WalletBloc>().add(LoadWalletsSubmitted());
  }

  Future<void> _onRefresh() async {
    _refreshController.resetNoData();
    _isRefreshing = true;
    context.read<WalletBloc>().add(RefreshWallets());
  }

  Widget _buildLoading() {
    return Skeletonizer(
      enabled: true,
      child: widget.loadingBuilder?.call(context) ??
          ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: 3,
            itemBuilder: (_, __) => const WalletCardLoading(),
          ),
    );
  }

  Widget _buildError(String message) {
    return widget.errorBuilder?.call(context, message) ??
        TErrorWidget(
          message: message,
          onRetry: _loadWallets,
        );
  }

  Widget _buildEmpty() {
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      enablePullDown: true,
      enablePullUp: false,
      child: widget.emptyBuilder?.call(context) ??
          const EmptyWidget(message: 'Bạn chưa có ví nào'),
    );
  }

  /// ✅ TRUNG TÂM QUYẾT ĐỊNH UI
  Widget _buildList(List<WalletModel> wallets) {
    if (wallets.isEmpty) return _buildEmpty();

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      enablePullDown: true,
      enablePullUp: false,
      child: widget.builder != null
          ? widget.builder!(context, wallets)
          : _buildWalletList(wallets),
    );
  }

  Widget _buildWalletList(List<WalletModel> wallets) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: wallets.length,
      itemBuilder: (context, index) {
        final wallet = wallets[index];

        return widget.itemBuilder != null
            ? widget.itemBuilder!(context, wallet, index)
            : WalletCard(wallet: wallet);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        switch (state) {
          case WalletFailure(:final message):
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

          case WalletLoaded(:final wallets):
            _refreshController.refreshCompleted();
            widget.onLoaded?.call(wallets);
            // Chỉ gọi onRefresh khi thực sự là refresh (không phải load lần đầu)
            if (_isRefreshing) {
              widget.onRefresh?.call();
              _isRefreshing = false;
            }

          case WalletDeleted():
            TLoaders.showNotification(
              context,
              type: NotificationType.success,
              title: 'Thành công',
              message: 'Xóa ví thành công',
            );
            // Refresh danh sách
            _loadWallets();

          case WalletDeleteFailure(:final message):
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
        WalletInitial() || WalletLoading() => _buildLoading(),
        WalletFailure(:final message) => _buildError(message),
        WalletLoaded(:final wallets) => _buildList(wallets),
        WalletRefreshing(:final wallets) => _buildList(wallets),
        _ => const SizedBox.shrink(),
      },
    );
  }
}