import 'package:finance_management_app/common/widgets/containers/primary_header_container.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/profile/user_profile_tile.dart';
import '../../../../common/widgets/text/section_heading.dart';
import '../../../../common/widgets/text/settings_menu_tile.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/image_strings.dart';
import '../../../../constants/sizes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          TPrimaryHeaderContainer(
            child: Column(
              children: [
                // Appbar
                TAppbar(
                  title: Text(
                    'Account',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .apply(color: TColors.white),
                  ),
                ),
      
                // User profile Card
                TUserProfileTile(
                  onPressed: () {},
                  fullName: 'Gia Bao',
                  email: 'ngbao08052003@gmail.com',
                  avatar: TImages.user,
                  isNetworkImage: false,
                ),
                const SizedBox(height: TSizes.spaceBtwSections),
              ],
            ),
          ),
      
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: TSizes.defaultSpace, right: TSizes.defaultSpace),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                  // Account Setting
                  const TSectionHeading(
                    title: 'Account Settings',
                    showActionButton: false,
                  ),
                  AppSpacing.h8,
                  
                  const TSettingsMenuTile(
                    title: 'Favorites',
                    subtitle: 'Save your favorite items',
                    icon: Iconsax.heart5,
                  ),
                  
                  const TSettingsMenuTile(
                    title: 'Categories',
                    subtitle: 'Organize and store your summaries',
                    icon: Iconsax.folder_open5,
                  ),
                  
                  const TSettingsMenuTile(
                    title: 'Language',
                    subtitle: 'Select your preferred language',
                    icon: Iconsax.global5,
                  ),
                  
                  // App Settings
                  const SizedBox(height: TSizes.spaceBtwSections),
                  const TSectionHeading(
                      title: 'App Settings', showActionButton: false),
                  AppSpacing.h8,
                  TSettingsMenuTile(
                    title: 'Dark Mode',
                    subtitle: 'Enable to switch to dark mode',
                    icon: Iconsax.moon5,
                  ),
                  const TSettingsMenuTile(
                    title: 'Rate App',
                    subtitle: 'Give us your feedback on the app',
                    icon: Iconsax.medal_star5,
                  ),
                  const TSettingsMenuTile(
                    title: 'Share App',
                    subtitle: 'Share this app with your friends',
                    icon: Iconsax.share5,
                  ),
                  
                  const TSettingsMenuTile(
                    title: 'Invite Friends',
                    subtitle: 'Invite your friends to use this app',
                    icon: Iconsax.user_add,
                  ),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Logout'),
                    ),
                  ),

                  SizedBox(height: 100)
                ],
              ),
            ),
          )
      )],
      ),
    );
  }
}
