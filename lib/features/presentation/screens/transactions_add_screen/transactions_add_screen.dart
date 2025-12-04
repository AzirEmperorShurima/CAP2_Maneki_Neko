import 'package:finance_management_app/common/widgets/appbar/appbar.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/features/presentation/screens/transactions_add_screen/tabs/transactions_add_expense.dart';
import 'package:finance_management_app/features/presentation/screens/transactions_add_screen/tabs/transactions_add_income.dart';
import 'package:finance_management_app/features/presentation/screens/transactions_add_screen/tabs/transactions_add_transfer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/custom_number_keyboard/custom_numeric_keyboard.dart';
import '../../../../common/widgets/tab_switcher/tab_switcher.dart';
import '../../../../constants/app_padding.dart';
import '../../../../utils/device/device_utility.dart';

class TransactionsAddScreen extends StatefulWidget {
  const TransactionsAddScreen({super.key});

  @override
  State<TransactionsAddScreen> createState() => _TransactionsAddScreenState();
}

class _TransactionsAddScreenState extends State<TransactionsAddScreen> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  String _amount = '0';
  String _note = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppbar(
        leadingIcon: Iconsax.close_square,
        leadingIconColor: TColors.primary,
        leadingIconSize: 28,
        leadingOnPressed: () => context.pop(),
        title: Text('Add Transactions',
            style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Iconsax.tick_square,
              size: 28,
              color: TColors.primary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(),
          Expanded(
            child: Padding(
              padding: AppPadding.h8,
              child: Column(
                children: [
                  AppSpacing.h4,
                  TabSwitcher(
                    tabs: const [
                      'Expense',
                      'Income',
                      'Transfer',
                    ],
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
                  AppSpacing.h8,
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (value) {
                        setState(() => _selectedIndex = value);
                      },
                      children: [
                        TransactionsAddExpense(),
                        TransactionsAddIncome(),
                        TransactionsAddTransfer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          CustomNumericKeyboard(
            amount: _amount,
            note: _note,
            onNumberPressed: (number) {
              setState(() {
                if (_amount == '0') {
                  _amount = number;
                } else {
                  _amount += number;
                }
              });
            },
            onBackspacePressed: () {
              setState(() {
                if (_amount.length > 1) {
                  _amount = _amount.substring(0, _amount.length - 1);
                } else {
                  _amount = '0';
                }
              });
            },
            onNoteChanged: (note) {
              setState(() {
                _note = note;
              });
            },
            onTodayPressed: () {
              // Handle today button
            },
            onEmojiPressed: () {
              // Handle emoji button
            },
            onPlusPressed: () {
              // Handle plus button
            },
            onOperatorPressed: (operator) {
              // Handle operator button
            },
          )
        ],
      ),
    );
  }
}
