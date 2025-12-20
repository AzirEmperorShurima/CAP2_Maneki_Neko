import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/api_builder/family_builder.dart';
import '../../../../common/widgets/family/invite_family_bottom_sheet.dart';
import '../../../../common/widgets/profile/t_circular_image.dart';
import '../../../../common/widgets/text/overflow_marquee_text.dart';
import '../../../../constants/app_border_radius.dart';
import '../../../../constants/app_padding.dart';
import '../../../../constants/app_spacing.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/image_strings.dart';
import '../../../../utils/device/device_utility.dart';
import '../../../../utils/popups/loaders.dart';
import 'tabs/family_analytics_summary_tab.dart';
import 'tabs/family_top_categories_tab.dart';
import 'tabs/family_top_wallets_tab.dart';
import 'tabs/family_user_breakdown_tab.dart';

class FamilyTab extends StatefulWidget {
  const FamilyTab({super.key});

  @override
  State<FamilyTab> createState() => _FamilyTabState();
}

class _FamilyTabState extends State<FamilyTab> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FamilyBuilder(
      builder: (context, family) {
        if (family == null) {
          return const Center(
            child: Text('Bạn chưa có gia đình nào'),
          );
        }

        return Column(
          children: [
            // Tabs - Lướt ngang
            Padding(
              padding: AppPadding.v8,
              child: _buildHorizontalTabs(context),
            ),

            // Family Header Card
            Padding(
              padding: AppPadding.h16.add(AppPadding.v8),
              child: _buildFamilyHeaderCard(context, family),
            ),
            AppSpacing.h8,

            // Tab Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() => _selectedIndex = value);
                },
                children: [
                  _buildFamilyInfoTab(context, family),
                  const FamilyAnalyticsSummaryTab(),
                  const FamilyUserBreakdownTab(),
                  const FamilyTopCategoriesTab(),
                  const FamilyTopWalletsTab(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalTabs(BuildContext context) {
    const tabs = [
      'Thông tin',
      'Tổng quan',
      'Thành viên',
      'Danh mục',
      'Top chi tiêu',
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppPadding.h16,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () {
              TDeviceUtils.lightImpact();
              setState(() => _selectedIndex = index);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              margin: EdgeInsets.only(
                right: index < tabs.length - 1 ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? TColors.primary : TColors.primary.withOpacity(0.1),
                borderRadius: AppBorderRadius.md,
              ),
              child: Center(
                child: Text(
                  tabs[index],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? Colors.white : TColors.primary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFamilyInfoTab(BuildContext context, family) {
    return SingleChildScrollView(
      padding: AppPadding.h16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invite Code Section
          _buildInviteCodeCard(context, family),
          AppSpacing.h16,

          // Action Buttons - chỉ hiển thị nút mời thành viên nếu đã có family
          _buildInviteButton(context),
          AppSpacing.h16,

          // Admin Section
          if (family.admin != null) ...[
            _buildSectionTitle(context, 'Người quản lý'),
            AppSpacing.h8,
            _buildMemberCard(context, family.admin!, isAdmin: true),
            AppSpacing.h16,
          ],

          // Members Section
          if (family.members != null && family.members!.isNotEmpty) ...[
            _buildSectionTitle(
              context,
              'Thành viên (${family.members!.length})',
            ),
            AppSpacing.h8,
            ...family.members!.map((member) => Padding(
                  padding: AppPadding.v4,
                  child: _buildMemberCard(context, member),
                )),
            AppSpacing.h16,
          ],

          // Pending Invites Section
          if (family.pendingInvites != null &&
              family.pendingInvites!.isNotEmpty) ...[
            _buildSectionTitle(
              context,
              'Lời mời đang chờ (${family.pendingInvites!.length})',
            ),
            AppSpacing.h8,
            ...family.pendingInvites!.map((invite) => Padding(
                  padding: AppPadding.v4,
                  child: _buildMemberCard(context, invite, isPending: true),
                )),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildFamilyHeaderCard(BuildContext context, family) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.md,
        color: TColors.white,
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withOpacity(0.2),
            blurRadius: 3,
            spreadRadius: 2,
            offset: Offset.zero,
          ),
        ],
      ),
      padding: AppPadding.a8,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            padding: AppPadding.a8,
            child: const Icon(
              Iconsax.people,
              color: TColors.primary,
              size: 25,
            ),
          ),
          AppSpacing.w16,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OverflowMarqueeText(
                text: family.name ?? 'Chưa có tên',
                style: Theme.of(context).textTheme.titleLarge
              ),
              AppSpacing.h4,
              Row(
                children: [
                  Icon(
                    Iconsax.verify5,
                    size: 16,
                    color: family.isActive == true
                        ? Colors.green
                        : Colors.grey,
                  ),
                  AppSpacing.w4,
                  Text(
                    family.isActive == true ? 'Đang hoạt động' : 'Không hoạt động',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: family.isActive == true
                              ? Colors.green
                              : Colors.grey,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCodeCard(BuildContext context, family) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.md,
        color: TColors.primary.withOpacity(0.1),
        border: Border.all(
          color: TColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: AppPadding.a16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.link,
                color: TColors.primary,
                size: 20,
              ),
              AppSpacing.w8,
              Text(
                'Mã mời',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: TColors.primary,
                    ),
              ),
            ],
          ),
          AppSpacing.h8,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: AppPadding.a8,
                  decoration: const BoxDecoration(
                    color: TColors.white,
                    borderRadius: AppBorderRadius.sm,
                  ),
                  child: Text(
                    family.inviteCode ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                  ),
                ),
              ),
              AppSpacing.w8,
              IconButton(
                onPressed: () {
                  if (family.inviteCode != null &&
                      family.inviteCode!.isNotEmpty) {
                    Clipboard.setData(
                      ClipboardData(text: family.inviteCode!),
                    );
                    TLoaders.showNotification(
                      context,
                      type: NotificationType.success,
                      title: 'Thành công',
                      message: 'Đã sao chép mã mời',
                    );
                  }
                },
                icon: const Icon(
                  Iconsax.copy,
                  color: TColors.primary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: TColors.white,
                  padding: AppPadding.a8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: TColors.black,
          ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    member, {
    bool isAdmin = false,
    bool isPending = false,
  }) {
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
      padding: AppPadding.a8,
      child: Row(
        children: [
          TCircularImage(
            image: (member.avatar != null && member.avatar!.isNotEmpty)
                ? member.avatar!
                : TImages.user,
            isNetworkImage: member.avatar != null && member.avatar!.isNotEmpty,
            width: 50,
            height: 50,
            padding: 0,
          ),
          AppSpacing.w12,
          Expanded(
            child: isPending && (member.username == null || member.username!.isEmpty)
                ? Column(
                  children: [
                    OverflowMarqueeText(
                      text: member.email ?? '',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      alignment: Alignment.centerLeft,
                    ),
                  ],
                )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OverflowMarqueeText(
                              text: member.username ?? 'Chưa có tên',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                          if (isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: TColors.primary.withOpacity(0.1),
                                borderRadius: AppBorderRadius.sm,
                              ),
                              child: Text(
                                'Quản lý',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: TColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          if (isPending)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: AppBorderRadius.sm,
                              ),
                              child: Text(
                                'Chờ',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      AppSpacing.h4,
                      Text(
                        member.email ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TColors.darkerGrey,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          InviteFamilyBottomSheet.show(context);
        },
        icon: const Icon(Iconsax.user_add, color: Colors.white),
        label: Text(
          'Mời thành viên',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: TColors.primary,
          padding: AppPadding.v16,
          shape: const RoundedRectangleBorder(
            borderRadius: AppBorderRadius.md,
          ),
        ),
      ),
    );
  }
}
