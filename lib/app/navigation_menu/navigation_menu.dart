import 'package:auto_route/auto_route.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:finance_management_app/app/navigation_menu/models/nav_item_model.dart';
import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/features/presentation/screens/star/star_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rive/rive.dart';

import '../../common/widgets/family/family_option_bottom_sheet.dart';
import '../../features/presentation/blocs/family/family_bloc.dart';
import '../../features/presentation/screens/chat/chat_screen.dart';
import '../../features/presentation/screens/home/home_screen.dart';
import '../../features/presentation/screens/settings/settings_screen.dart';
import '../../features/presentation/screens/transactions/transactions_screen.dart';
import '../../routes/router.gr.dart';
import '../../utils/device/device_utility.dart';

@RoutePage()
class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  List<SMIBool?> riveIconInputs = [];
  List<StateMachineController?> controllers = [];
  int selectedNavIndex = 0;

  final List<Widget> pages = const [
    HomeScreen(),
    ChatScreen(),
    TransactionsScreen(),
    StarScreen(),
    SettingsScreen(),
  ];

  void animateTheIcon(int index) {
    Future.delayed(const Duration(seconds: 1), () {
      final input = riveIconInputs[index];
      if (input != null) {
        input.change(false);
      }
    });
  }

  void riveOnInit(Artboard artboard,
      {required String stateMachineName, required int index}) {
    final StateMachineController? controller =
        StateMachineController.fromArtboard(
      artboard,
      stateMachineName,
    );
    controllers.add(controller);

    if (controller != null) {
      artboard.addController(controller);
      riveIconInputs[index] = controller.findInput<bool>('active') as SMIBool?;
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize with null values for all icons
    riveIconInputs = List<SMIBool?>.filled(bottomNavItems.length, null);

    // Trigger intro animation for all icons after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _playIntroAnimation();
    });
  }

  void _playIntroAnimation() {
    for (int i = 0; i < riveIconInputs.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        final input = riveIconInputs[i];
        if (input != null) {
          input.change(true);
          // Reset after animation
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              input.change(false);
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
          body: Stack(
        children: [
          pages[selectedNavIndex],
          BlocBuilder<FamilyBloc, FamilyState>(
            builder: (context, familyState) {
              // Kiểm tra điều kiện hiển thị button
              final shouldShowButton = selectedNavIndex == 0 || 
                  (selectedNavIndex == 3 && StarScreen.selectedTabIndex == 0) ||
                  (selectedNavIndex == 3 && 
                   StarScreen.selectedTabIndex == 1 &&
                   !(familyState is FamilyLoaded && familyState.family != null));
              
              if (!shouldShowButton) {
                return const SizedBox.shrink();
              }
              
              // Xác định icon
              IconData icon;
              if (selectedNavIndex == 0) {
                icon = Iconsax.edit;
              } else if (selectedNavIndex == 3) {
                if (StarScreen.selectedTabIndex == 1) {
                  // Tab Family - hiển thị icon join
                  icon = Iconsax.login;
                } else {
                  // Tab Budget
                  icon = Iconsax.add_square;
                }
              } else {
                icon = Iconsax.add_square;
              }
              
              return Positioned(
                right: 24,
                bottom: 100,
                child: AvatarGlow(
                  animate: true,
                  glowColor: TColors.primary,
                  duration: const Duration(seconds: 2),
                  repeat: true,
                  glowRadiusFactor: 0.25,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: FloatingActionButton(
                      onPressed: () {
                        TDeviceUtils.lightImpact();
                        if (selectedNavIndex == 0) {
                          AutoRouter.of(context).push(TransactionsAddScreenRoute());
                        } else if (selectedNavIndex == 3) {
                          // StarScreen - kiểm tra tab hiện tại
                          final selectedTabIndex = StarScreen.selectedTabIndex;
                          if (selectedTabIndex == 0) {
                            // Tab Budget
                            AutoRouter.of(context).push(BudgetAddScreenRoute());
                        } else {
                          // Tab Family - hiển thị option tạo hoặc join
                          final currentFamilyState = context.read<FamilyBloc>().state;
                          if (currentFamilyState is FamilyLoaded && 
                              currentFamilyState.family != null) {
                            // Đã có family, không làm gì
                            return;
                          } else {
                            // Chưa có family, hiển thị bottom sheet chọn option
                            FamilyOptionBottomSheet.show(context);
                          }
                        }
                        } else {
                          AutoRouter.of(context).push(BudgetAddScreenRoute());
                        }
                      },
                      backgroundColor: TColors.primary,
                      elevation: 2,
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Container(
                padding: AppPadding.a8.add(AppPadding.a4),
                decoration: const BoxDecoration(
                  color: TColors.primary,
                  borderRadius: AppBorderRadius.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    bottomNavItems.length,
                    (index) {
                      final riveIcon = bottomNavItems[index].rive;
                      final isTransactionButton = index == 2;

                      return GestureDetector(
                        onTap: () {
                          TDeviceUtils.lightImpact();
                          final input = riveIconInputs[index];
                          if (input != null) {
                            input.change(true);
                            animateTheIcon(index);
                            if (index == 1) {
                              AutoRouter.of(context)
                                  .push(const ChatScreenRoute());
                            } else {
                              setState(() {
                                selectedNavIndex = index;
                              });
                            }
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isTransactionButton)
                              AnimatedBar(
                                isActive: selectedNavIndex == index,
                              ),
                            Container(
                              height: isTransactionButton ? 46 : 36,
                              width: isTransactionButton ? 46 : 36,
                              decoration: isTransactionButton
                                  ? BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: AppBorderRadius.sm,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    )
                                  : null,
                              child: Center(
                                child: SizedBox(
                                  height: 36,
                                  width: 36,
                                  child: ColorFiltered(
                                    colorFilter: isTransactionButton
                                        ? const ColorFilter.mode(
                                            TColors.primary,
                                            BlendMode.srcIn,
                                          )
                                        : const ColorFilter.mode(
                                            Colors.transparent,
                                            BlendMode.dst,
                                          ),
                                    child: Opacity(
                                      opacity: isTransactionButton
                                          ? 1
                                          : selectedNavIndex == index
                                              ? 1
                                              : 0.5,
                                      child: RiveAnimation.asset(
                                        riveIcon.src,
                                        artboard: riveIcon.artboard,
                                        onInit: (artboard) {
                                          riveOnInit(
                                            artboard,
                                            stateMachineName:
                                                riveIcon.stateMachineName,
                                            index: index,
                                          );
                                        },
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
                  ),
                )),
          )
        ],
      ),
    );
  }
}

class AnimatedBar extends StatelessWidget {
  final bool isActive;

  const AnimatedBar({
    super.key,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 2),
      height: 4,
      width: isActive ? 20 : 0,
      decoration: const BoxDecoration(
          color: Color(0xFF81B4FF), borderRadius: AppBorderRadius.md),
    );
  }
}
