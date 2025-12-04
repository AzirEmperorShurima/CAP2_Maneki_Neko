import 'package:finance_management_app/common/widgets/text/price_text.dart';
import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/utils/device/device_utility.dart';
import 'package:flutter/material.dart';

class CustomNumericKeyboard extends StatefulWidget {
  final Function(String)? onNumberPressed;
  final Function()? onBackspacePressed;
  final Function()? onTodayPressed;
  final Function()? onEmojiPressed;
  final Function()? onPlusPressed;
  final Function(String)? onOperatorPressed;
  final Function(String)? onNoteChanged;
  final String amount;
  final String note;
  final String transactionType;

  const CustomNumericKeyboard({
    super.key,
    this.onNumberPressed,
    this.onBackspacePressed,
    this.onTodayPressed,
    this.onEmojiPressed,
    this.onPlusPressed,
    this.onOperatorPressed,
    this.onNoteChanged,
    this.amount = '0',
    this.note = '',
    this.transactionType = 'Chi tiêu',
  });

  @override
  State<CustomNumericKeyboard> createState() => _CustomNumericKeyboardState();
}

class _CustomNumericKeyboardState extends State<CustomNumericKeyboard> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.note);
  }

  @override
  void didUpdateWidget(CustomNumericKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note != oldWidget.note) {
      _noteController.text = widget.note;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _handleNumberPress(String number) {
    widget.onNumberPressed?.call(number);
  }

  void _handleBackspace() {
    widget.onBackspacePressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: AppPadding.h16.add(AppPadding.v16),
          decoration: BoxDecoration(
            color: TColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Hàng đầu tiên (icon - note - amount) chỉnh đều 4 cột
              _buildKeyboardButton(
                backgroundColor: Colors.white,
                onPressed: () {},
                child: Padding(
                  padding: AppPadding.h16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/images/icons/wallet.png',
                              height: 28),
                          AppSpacing.w16,
                          Container(
                            width: 1,
                            height: 20,
                            color: TColors.softGrey,
                          ),
                          AppSpacing.w16,
                          Text(
                            'Note',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          AppSpacing.w16,
                          Container(
                            width: 1,
                            height: 20,
                            color: TColors.softGrey,
                          ),
                        ],
                      ),
                      // Expanded(
                      //   child: Align(
                      //     alignment: Alignment.centerRight,
                      //     child: Text(
                      //       widget.amount,
                      //       style: const TextStyle(
                      //         fontSize: 16,
                      //         fontWeight: FontWeight.w600,
                      //       ),
                      //       maxLines: 1,
                      //       overflow: TextOverflow.ellipsis,
                      //     ),
                      //   ),
                      // ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: PriceText(
                            amount: widget.amount,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AppSpacing.h8,
              AppSpacing.h4,

              // Row 1: Emoji, TODAY, Plus, Check
              Row(
                children: [
                  Expanded(
                    child: _buildKeyboardButton(
                      child: Image.asset(
                        'assets/images/icons/member.png',
                        height: 30,
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: widget.onEmojiPressed ?? () {},
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(
                    child: _buildKeyboardButton(
                      child: Text(
                        'TODAY',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: widget.onTodayPressed ?? () {},
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(
                    child: _buildKeyboardButton(
                      child: Image.asset(
                        'assets/images/icons/plus.png',
                        height: 26,
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: widget.onPlusPressed ?? () {},
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(
                    child: _buildKeyboardButton(
                      child: Image.asset(
                        'assets/images/icons/check.png',
                        height: 26,
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: widget.onPlusPressed ?? () {},
                    ),
                  ),
                ],
              ),

              AppSpacing.h8,
              // Row 2: X, 7, 8, 9
              Row(
                children: [
                  Expanded(
                    child: _buildKeyboardButton(
                      child: const Text(
                        'X',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: () => widget.onOperatorPressed?.call('*'),
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('7')),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('8')),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('9')),
                ],
              ),

              AppSpacing.h8,
              // Row 3: /, 4, 5, 6
              Row(
                children: [
                  Expanded(
                    child: _buildKeyboardButton(
                      child: const Text(
                        '/',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: () => widget.onOperatorPressed?.call('/'),
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('4')),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('5')),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('6')),
                ],
              ),

              AppSpacing.h8,
              // Row 4: -, 1, 2, 3
              Row(
                children: [
                  Expanded(
                    child: _buildKeyboardButton(
                      child: const Text(
                        '-',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: () => widget.onOperatorPressed?.call('-'),
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('1')),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('2')),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('3')),
                ],
              ),

              AppSpacing.h8,
              // Row 5: +, ., 0, Backspace
              Row(
                children: [
                  Expanded(
                    child: _buildKeyboardButton(
                      child: const Text(
                        '+',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: () => widget.onOperatorPressed?.call('+'),
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('.')),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('0')),
                  AppSpacing.w12,
                  Expanded(
                    child: _buildKeyboardButton(
                      child: Image.asset(
                        'assets/images/icons/close.png',
                        height: 26,
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: _handleBackspace,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return _buildKeyboardButton(
      child: Text(
        number,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.white,
      onPressed: () => _handleNumberPress(number),
    );
  }

  Widget _buildKeyboardButton({
    required Widget child,
    Color? backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          TDeviceUtils.lightImpact();
          onPressed();
        },
        borderRadius: AppBorderRadius.md,
        child: Container(
          height: 38,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor ?? TColors.white,
            borderRadius: AppBorderRadius.md,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
