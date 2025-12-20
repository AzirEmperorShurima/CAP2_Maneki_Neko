import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/profile/t_circular_image.dart';
import '../../../../../common/widgets/text/overflow_marquee_text.dart';
import '../../../../../common/widgets/text/price_text.dart';
import '../../../../../constants/app_border_radius.dart';
import '../../../../../constants/app_padding.dart';
import '../../../../../constants/app_spacing.dart';
import '../../../../../constants/colors.dart';
import '../../../../../constants/image_strings.dart';
import '../../../../domain/entities/family_top_wallets_model.dart';
import '../../../blocs/family/family_bloc.dart';

class FamilyTopWalletsTab extends StatefulWidget {
  const FamilyTopWalletsTab({super.key});

  @override
  State<FamilyTopWalletsTab> createState() => _FamilyTopWalletsTabState();
}

class _FamilyTopWalletsTabState extends State<FamilyTopWalletsTab> {
  FamilyTopWalletsModel? _cachedData;

  void _ensureDataLoaded() {
    if (_cachedData == null) {
      context.read<FamilyBloc>().add(LoadFamilyTopWallets());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyBloc, FamilyState>(
      builder: (context, state) {
        // Lưu lại data khi state là Loaded
        if (state is FamilyTopWalletsLoaded) {
          _cachedData = state.topWallets;
        }

        // Nếu state không phải là state của tab này
        if (!(state is FamilyTopWalletsLoading ||
            state is FamilyTopWalletsLoaded ||
            state is FamilyTopWalletsFailure)) {
          // Nếu đã có data cache, hiển thị data đó
          if (_cachedData != null) {
            return _buildContent(_cachedData!);
          }
          // Nếu chưa có data, dispatch event để load
          _ensureDataLoaded();
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FamilyTopWalletsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FamilyTopWalletsFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lỗi: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                ),
                AppSpacing.h16,
                ElevatedButton(
                  onPressed: () {
                    _cachedData = null;
                    context.read<FamilyBloc>().add(LoadFamilyTopWallets());
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (state is FamilyTopWalletsLoaded) {
          final topWallets = state.topWallets;
          if (topWallets == null) {
            return const Center(
              child: Text('Không có dữ liệu'),
            );
          }

          return _buildContent(topWallets);
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildContent(FamilyTopWalletsModel topWallets) {
    return SingleChildScrollView(
      padding: AppPadding.a16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Spender Card
          _buildTopSpenderCard(context, topWallets),
          AppSpacing.h16,

          // Info Card
          _buildInfoCard(context, topWallets),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTopSpenderCard(
    BuildContext context,
    FamilyTopWalletsModel topWallets,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.md,
        color: TColors.primary.withOpacity(0.1),
        border: Border.all(
          color: TColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      padding: AppPadding.a16,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: TColors.primary,
                  shape: BoxShape.circle,
                ),
                padding: AppPadding.a8,
                child: const Icon(
                  Iconsax.crown1,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              AppSpacing.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thành viên chi tiêu nhiều nhất',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: TColors.primary,
                          ),
                    ),
                    AppSpacing.h4,
                    Text(
                      'Top Spender',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: TColors.darkerGrey,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.h16,
          const Divider(),
          AppSpacing.h16,
          Row(
            children: [
              TCircularImage(
                image: TImages.user,
                isNetworkImage: false,
                width: 60,
                height: 60,
                padding: 0,
              ),
              AppSpacing.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OverflowMarqueeText(
                      text: topWallets.username ??
                          topWallets.email ??
                          'Chưa có tên',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      alignment: Alignment.centerLeft,
                    ),
                    if (topWallets.email != null) ...[
                      AppSpacing.h4,
                      Text(
                        topWallets.email!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TColors.darkerGrey,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    FamilyTopWalletsModel topWallets,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.md,
        color: TColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: AppPadding.a16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.h16,
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Tổng chi tiêu',
                  topWallets.total ?? 0,
                  Colors.red,
                  Iconsax.wallet_money,
                ),
              ),
              AppSpacing.w8,
              Expanded(
                child: _buildStatItem(
                  context,
                  'Giao dịch',
                  topWallets.count?.toDouble() ?? 0,
                  TColors.primary,
                  Iconsax.receipt,
                  isCount: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    double value,
    Color color,
    IconData icon, {
    bool isCount = false,
  }) {
    return Container(
      padding: AppPadding.a8,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppBorderRadius.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              AppSpacing.w8,
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TColors.darkerGrey,
                      ),
                ),
              ),
            ],
          ),
          AppSpacing.h8,
          if (isCount)
            Text(
              value.toInt().toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            )
          else
            PriceText(
              amount: value.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              currencyStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    decoration: TextDecoration.underline,
                    decorationColor: color,
                  ),
            ),
        ],
      ),
    );
  }
}
