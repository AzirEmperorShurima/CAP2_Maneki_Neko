import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/features/presentation/screens/transactions/tabs/transactions_analysis.dart';
import 'package:finance_management_app/features/presentation/screens/transactions/tabs/transactions_wallet.dart';
import 'package:flutter/material.dart';

import '../../../../common/widgets/tab_switcher/tab_switcher.dart';
import '../../../../constants/app_padding.dart';
import '../../../../utils/device/device_utility.dart';

@RoutePage()
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: TColors.primary,
        title: TabSwitcher(
          iconPaths: const [
            'assets/images/icons/wallet.png',
            'assets/images/icons/analysis.png',
          ],
          tabs: const [
            'Ví tiền',
            'Phân tích',
          ],
          backgroundColor: TColors.white,
          isSelectedColors: TColors.primary,
          isUnSelectedColors: TColors.white,
          isSelectedTextColors: Colors.white,
          isUnSelectedTextColors: Colors.black,
          padding: AppPadding.a8.add(AppPadding.a2),
          selectedIndex: _selectedIndex,
          onTabSelected: (index) {
            TDeviceUtils.lightImpact();
            setState(() => _selectedIndex = index);
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
          setState(() => _selectedIndex = value);
        },
        children: const [
          TransactionsWallet(),
          TransactionsAnalysis(),
        ],
      ),
    );
  }
}
