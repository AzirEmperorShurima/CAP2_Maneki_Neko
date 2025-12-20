import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../common/widgets/tab_switcher/tab_switcher.dart';
import '../../../../constants/app_padding.dart';
import '../../../../constants/colors.dart';
import '../../../../utils/device/device_utility.dart';
import '../budget/budget.dart';
import '../family/family.dart';

@RoutePage()
class StarScreen extends StatefulWidget {
  const StarScreen({super.key});

  @override
  State<StarScreen> createState() => _StarScreenState();

  static int selectedTabIndex = 0;
}

class _StarScreenState extends State<StarScreen> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    StarScreen.selectedTabIndex = _selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: TColors.primary,
        title: TabSwitcher(
          iconPaths: const [
            'assets/images/icons/budget.png',
            'assets/images/icons/family.png',
          ],
          tabs: const [
            'Ngân sách',
            'Gia đình',
          ],
          backgroundColor: TColors.white,
          isSelectedColors: TColors.primary,
          isUnSelectedColors: TColors.white,
          isSelectedTextColors: Colors.white,
          isUnSelectedTextColors: Colors.black,
          padding: AppPadding.a8,
          
          selectedIndex: _selectedIndex,
          onTabSelected: (index) {
            TDeviceUtils.lightImpact();
            setState(() {
              _selectedIndex = index;
              StarScreen.selectedTabIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (value) {
          setState(() {
            _selectedIndex = value;
            StarScreen.selectedTabIndex = value;
          });
        },
        children: const [
          BudgetTab(),
          FamilyTab(),
        ],
      ),
    );
  }
}
