import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/common/widgets/containers/primary_header_container.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/loading/loading/loading.dart';
import '../../../../common/widgets/profile/user_profile_tile.dart';
import '../../../../common/widgets/text/section_heading.dart';
import '../../../../common/widgets/text/settings_menu_tile.dart';
import '../../../../constants/app_border_radius.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/image_strings.dart';
import '../../../../constants/sizes.dart';
import '../../../../routes/router.gr.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/user/user_bloc.dart';

@RoutePage()
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  void showLogoutDialog(BuildContext context) {
    TLoaders.showConfirmActionSheet(
      context: context,
      title: 'Đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất?',
      confirmText: 'Đăng xuất',
      cancelText: 'Hủy',
      onConfirm: () async {
        context.read<SettingsBloc>().add(SettingsLogout());
      },
      onCancel: () async => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        // Logout success
        if (state is SettingsLogoutSuccess) {
          TLoaders.showNotification(
            context,
            type: NotificationType.success,
            title: 'Đăng xuất thành công',
            message: 'Bạn đã đăng xuất thành công',
          );
          AutoRouter.of(context).replaceAll([const LoginScreenRoute()]);
        }

        // Logout failure
        if (state is SettingsLogoutFailure) {
          TLoaders.showNotification(
            context,
            type: NotificationType.error,
            title: 'Đăng xuất thất bại',
            message: state.message,
          );
        }
      },
      builder: (context, state) {
        return BlocBuilder<UserBloc, UserState>(
          builder: (context, userState) {
            final user = userState is UserLoaded ? userState.user : null;

            return Scaffold(
              body: Column(
                children: [
                  // Header
                  TPrimaryHeaderContainer(
                    child: Column(
                      children: [
                        // AppBar
                        TAppBar(
                          title: Text(
                            'Tài khoản',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .apply(color: TColors.white),
                          ),
                        ),

                        // User profile Card
                        TUserProfileTile(
                          onPressed: () => AutoRouter.of(context)
                              .push(const ProfileScreenRoute()),
                          fullName: user?.username ?? 'Người dùng',
                          email: user?.email ?? 'Chưa cập nhật',
                          avatar:
                              user?.avatar != null && user!.avatar!.isNotEmpty
                                  ? user.avatar!
                                  : TImages.user,
                          isNetworkImage:
                              user?.avatar != null && user!.avatar!.isNotEmpty,
                        ),
                        const SizedBox(height: TSizes.spaceBtwSections),
                      ],
                    ),
                  ),

                  // Body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: TSizes.defaultSpace,
                          right: TSizes.defaultSpace),
                      child: AnimationLimiter(
                        child: SingleChildScrollView(
                          child: Column(
                            children: AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 275),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: widget,
                                ),
                              ),
                              children: [
                                // Account Setting
                                const TSectionHeading(
                                  title: 'Cài đặt tài khoản',
                                  showActionButton: false,
                                ),
                                AppSpacing.h8,

                                const TSettingsMenuTile(
                                  title: 'Yêu thích',
                                  subtitle: 'Lưu các mục yêu thích của bạn',
                                  icon: Iconsax.heart5,
                                ),

                                const TSettingsMenuTile(
                                  title: 'Danh mục',
                                  subtitle:
                                      'Tổ chức và lưu trữ tóm tắt của bạn',
                                  icon: Iconsax.folder_open5,
                                ),

                                const TSettingsMenuTile(
                                  title: 'Ngôn ngữ',
                                  subtitle: 'Chọn ngôn ngữ ưa thích của bạn',
                                  icon: Iconsax.global5,
                                ),

                                // App Settings
                                const SizedBox(height: TSizes.spaceBtwItems),
                                const TSectionHeading(
                                    title: 'Cài đặt ứng dụng',
                                    showActionButton: false),
                                AppSpacing.h8,
                                TSettingsMenuTile(
                                  title: 'Chế độ tối',
                                  subtitle: 'Bật để chuyển sang chế độ tối',
                                  icon: Iconsax.moon5,
                                  onTap: () => showThemeBottomSheet(context),
                                ),
                                const TSettingsMenuTile(
                                  title: 'Đánh giá ứng dụng',
                                  subtitle: 'Gửi phản hồi của bạn về ứng dụng',
                                  icon: Iconsax.medal_star5,
                                ),
                                const TSettingsMenuTile(
                                  title: 'Chia sẻ ứng dụng',
                                  subtitle: 'Chia sẻ ứng dụng này với bạn bè',
                                  icon: Iconsax.share5,
                                ),

                                const TSettingsMenuTile(
                                  title: 'Mời bạn bè',
                                  subtitle: 'Mời bạn bè sử dụng ứng dụng này',
                                  icon: Iconsax.user_add,
                                ),

                                // Logout Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => showLogoutDialog(context),
                                    child: state is SettingsLogoutLoading
                                        ? TLoadingSpinkit.loadingButton
                                        : const Text('Đăng xuất'),
                                  ),
                                ),
                                const SizedBox(height: 100)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showThemeBottomSheet(BuildContext context) {
    TLoaders.bottomSheet(
      context: context,
      borderRadius: AppBorderRadius.md,
      heightPercentage: 0.3,
      child: Column(
        children: [
          Text('Chế độ hiển thị',
              style: Theme.of(context).textTheme.headlineSmall),
          Divider(color: TColors.grey.withOpacity(0.5)),
          Padding(
            padding: AppPadding.v8.add(AppPadding.h16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: AppPadding.v8,
                  child: Text('Chế độ sáng',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Divider(color: TColors.grey.withOpacity(0.5)),
                Padding(
                  padding: AppPadding.v8,
                  child: Text('Chế độ tối',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Divider(color: TColors.grey.withOpacity(0.5)),
                Padding(
                  padding: AppPadding.v8,
                  child: Text('Chế độ theo hệ thống',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
