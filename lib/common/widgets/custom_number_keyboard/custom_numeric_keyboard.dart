import 'package:finance_management_app/common/widgets/text/price_text.dart';
import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/utils/device/device_utility.dart';
import 'package:finance_management_app/utils/formatters/formatter.dart';
import 'package:finance_management_app/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';

class CustomNumericKeyboard extends StatefulWidget {
  final Function(String)? onNumberPressed;

  final Function()? onBackspacePressed;

  final Function()? onDatePressed;

  final Function()? onMemberPressed;

  final Function()? onPlusPressed;

  final Function()? onWalletPressed;

  final Function(String)? onOperatorPressed;

  final Function(String)? onNoteChanged;

  final Function()? onEqualPressed;

  /// Callback khi amount được tính toán (nhận kết quả tính toán)
  final Function(String)? onAmountCalculated;

  final Function()? onCheckPressed;

  final String amount;

  final String note;

  final String transactionType;

  final DateTime? selectedDate;

  /// Trạng thái loading (để hiển thị loading cho nút plus và check)
  final bool isLoading;

  const CustomNumericKeyboard({
    super.key,
    this.onNumberPressed,
    this.onBackspacePressed,
    this.onDatePressed,
    this.onMemberPressed,
    this.onPlusPressed,
    this.onWalletPressed,
    this.onOperatorPressed,
    this.onNoteChanged,
    this.onEqualPressed,
    this.onCheckPressed,
    this.onAmountCalculated,
    this.amount = '0',
    this.note = '',
    this.transactionType = 'Chi tiêu',
    this.selectedDate,
    this.isLoading = false,
  });

  @override
  State<CustomNumericKeyboard> createState() => _CustomNumericKeyboardState();
}

class _CustomNumericKeyboardState extends State<CustomNumericKeyboard> {
  late TextEditingController _noteController;
  bool _isNoteExpanded = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.note);
    _noteController.addListener(_onNoteChanged);
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
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    super.dispose();
  }

  void _onNoteChanged() {
    widget.onNoteChanged?.call(_noteController.text);
  }

  void _handleNumberPress(String number) {
    widget.onNumberPressed?.call(number);
  }

  void _handleBackspace() {
    widget.onBackspacePressed?.call();
  }

  void _toggleNoteExpanded() {
    setState(() {
      _isNoteExpanded = !_isNoteExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: AppPadding.h16.add(AppPadding.v16),
          decoration: const BoxDecoration(
            color: TColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // TextField cho ghi chú (expand/collapse)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isNoteExpanded
                    ? Container(
                        decoration: BoxDecoration(
                          color: isDark ? TColors.darkContainer : TColors.white,
                          borderRadius: AppBorderRadius.md,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: _noteController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Nhập ghi chú...',
                            border: InputBorder.none,
                            hintStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: TColors.grey),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          minLines: 1,
                          autofocus: true,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              // Hàng đầu tiên (icon - note - amount) chỉnh đều 4 cột
              _buildKeyboardButton(
                backgroundColor: isDark ? TColors.darkContainer : Colors.white,
                onPressed: () {},
                context: context,
                child: Padding(
                  padding: AppPadding.h16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              TDeviceUtils.lightImpact();
                              widget.onWalletPressed?.call();
                            },
                            child: Image.asset('assets/images/icons/wallet.png',
                                height: 28),
                          ),
                          AppSpacing.w16,
                          Container(
                            width: 1,
                            height: 20,
                            color: TColors.softGrey,
                          ),
                          AppSpacing.w16,
                          GestureDetector(
                            onTap: () {
                              TDeviceUtils.lightImpact();
                              _toggleNoteExpanded();
                            },
                            child: Text(
                              'Ghi chú',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          AppSpacing.w16,
                          Container(
                            width: 1,
                            height: 20,
                            color: TColors.softGrey,
                          ),
                        ],
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _buildAmountDisplay(),
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
                      onPressed: widget.onMemberPressed ?? () {},
                      context: context,
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(
                    child: _buildKeyboardButton(
                      child: Text(
                        _getDateText(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: widget.onDatePressed ?? () {},
                      context: context,
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(
                    child: _buildKeyboardButton(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: TColors.primary,
                              ),
                            )
                          : Image.asset(
                              'assets/images/icons/plus.png',
                              height: 26,
                            ),
                      backgroundColor: TColors.primaryLight,
                      onPressed:
                          widget.isLoading || widget.onPlusPressed == null
                              ? () {}
                              : widget.onPlusPressed!,
                      context: context,
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(
                    child: _buildKeyboardButton(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: TColors.primary,
                              ),
                            )
                          : Image.asset(
                              _hasOperator()
                                  ? 'assets/images/icons/equal.png'
                                  : 'assets/images/icons/check.png',
                              height: 26,
                            ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: widget.isLoading
                          ? () {}
                          : (_hasOperator()
                              ? () {
                                  // Tính toán expression
                                  try {
                                    final result =
                                        _calculateExpression(widget.amount);
                                    // Nếu là số nguyên, bỏ phần thập phân
                                    final formattedResult = result % 1 == 0
                                        ? result.toInt().toString()
                                        : result.toString();
                                    widget.onAmountCalculated
                                        ?.call(formattedResult);
                                    widget.onEqualPressed?.call();
                                  } catch (e) {
                                    widget.onAmountCalculated?.call('0');
                                    widget.onEqualPressed?.call();
                                  }
                                }
                              : () {
                                  widget.onCheckPressed?.call();
                                }),
                      context: context,
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
                      child: Text(
                        'X',
                        style: TextStyle(
                          color: isDark ? TColors.light : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: () => widget.onOperatorPressed?.call('*'),
                      context: context,
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('7', context)),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('8', context)),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('9', context)),
                ],
              ),

              AppSpacing.h8,
              // Row 3: /, 4, 5, 6
              Row(
                children: [
                  Expanded(
                    child: _buildKeyboardButton(
                      child: Text(
                        '/',
                        style: TextStyle(
                          color: isDark ? TColors.light : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: () => widget.onOperatorPressed?.call('/'),
                      context: context,
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('4', context)),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('5', context)),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('6', context)),
                ],
              ),

              AppSpacing.h8,
              // Row 4: -, 1, 2, 3
              Row(
                children: [
                  Expanded(
                    child: _buildKeyboardButton(
                      child: Text(
                        '-',
                        style: TextStyle(
                          color: isDark ? TColors.light : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: () => widget.onOperatorPressed?.call('-'),
                      context: context,
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('1', context)),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('2', context)),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('3', context)),
                ],
              ),

              AppSpacing.h8,
              // Row 5: +, ., 0, Backspace
              Row(
                children: [
                  Expanded(
                    child: _buildKeyboardButton(
                      child: Text(
                        '+',
                        style: TextStyle(
                          color: isDark ? TColors.light : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: () => widget.onOperatorPressed?.call('+'),
                      context: context,
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('.', context)),
                  AppSpacing.w12,
                  Expanded(child: _buildNumberButton('0', context)),
                  AppSpacing.w12,
                  Expanded(
                    child: _buildKeyboardButton(
                      child: Image.asset(
                        'assets/images/icons/close.png',
                        height: 26,
                      ),
                      backgroundColor: TColors.primaryLight,
                      onPressed: _handleBackspace,
                      context: context,
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

  Widget _buildNumberButton(String number, BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    return _buildKeyboardButton(
      child: Text(
        number,
        style: TextStyle(
          color: isDark ? TColors.light : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isDark ? TColors.darkContainer : Colors.white,
      onPressed: () => _handleNumberPress(number),
      context: context,
    );
  }

  Widget _buildKeyboardButton({
    required Widget child,
    Color? backgroundColor,
    required VoidCallback onPressed,
    BuildContext? context,
  }) {
    final isDark =
        context != null ? THelperFunctions.isDarkMode(context) : false;
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
            color: backgroundColor ??
                (isDark ? TColors.darkContainer : TColors.white),
            borderRadius: AppBorderRadius.md,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  /// Kiểm tra xem amount có chứa operator không
  bool _hasOperator() {
    final amount = widget.amount.trim();
    if (amount.isEmpty || amount == '0') return false;

    final operators = ['+', '-', '*', '/'];
    return operators.any((op) => amount.contains(op));
  }

  /// Hiển thị amount, nếu có operator thì hiển thị expression với format số, không thì format số
  Widget _buildAmountDisplay() {
    final amount = widget.amount.trim();
    if (amount.isEmpty || amount == '0') {
      return PriceText(
        amount: '0',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: TColors.white,
            ),
        currencyStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: TColors.white,
              decoration: TextDecoration.underline,
              decorationColor: TColors.white,
            ),
      );
    }

    // Kiểm tra xem có chứa operator không
    final operators = ['+', '-', '*', '/'];
    final hasOperator = operators.any((op) => amount.contains(op));

    if (hasOperator) {
      // Format expression: format từng số trong expression, giữ nguyên operator
      final displayExpression = _formatExpression(amount);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Text(
          displayExpression,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: TColors.black,
              ),
          textAlign: TextAlign.right,
        ),
      );
    } else {
      // Hiển thị số đã format
      return PriceText(
        amount: amount,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: TColors.black,
            ),
        currencyStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: TColors.black,
              decoration: TextDecoration.underline,
              decorationColor: TColors.black,
            ),
      );
    }
  }

  /// Tính toán biểu thức
  double _calculateExpression(String expression) {
    if (expression.isEmpty || expression == '0') return 0;

    // Loại bỏ khoảng trắng
    expression = expression.replaceAll(' ', '');

    // Kiểm tra nếu expression kết thúc bằng operator
    if (['+', '-', '*', '/'].contains(expression[expression.length - 1])) {
      expression = expression.substring(0, expression.length - 1);
    }

    if (expression.isEmpty) return 0;

    // Xử lý phép nhân và chia trước
    final List<String> tokens = [];
    String currentNumber = '';

    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];
      if (['+', '-', '*', '/'].contains(char)) {
        if (currentNumber.isNotEmpty) {
          tokens.add(currentNumber);
          currentNumber = '';
        }
        tokens.add(char);
      } else {
        currentNumber += char;
      }
    }
    if (currentNumber.isNotEmpty) {
      tokens.add(currentNumber);
    }

    // Xử lý phép nhân và chia
    final List<String> processedTokens = [];
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == '*' || tokens[i] == '/') {
        if (processedTokens.isEmpty || i + 1 >= tokens.length) {
          throw Exception('Invalid expression');
        }
        final left = double.parse(processedTokens.removeLast());
        final operator = tokens[i];
        final right = double.parse(tokens[++i]);
        final result = operator == '*' ? left * right : left / right;
        processedTokens.add(result.toString());
      } else {
        processedTokens.add(tokens[i]);
      }
    }

    // Xử lý phép cộng và trừ
    if (processedTokens.isEmpty) return 0;

    double result = double.parse(processedTokens[0]);
    for (int i = 1; i < processedTokens.length; i += 2) {
      if (i + 1 >= processedTokens.length) break;
      final operator = processedTokens[i];
      final right = double.parse(processedTokens[i + 1]);
      if (operator == '+') {
        result += right;
      } else if (operator == '-') {
        result -= right;
      }
    }

    return result;
  }

  /// Format expression: format từng số trong expression, giữ nguyên operator
  String _formatExpression(String expression) {
    final operators = ['+', '-', '*', '/'];

    // Tách expression thành các phần: số và operator
    final List<String> parts = [];
    String currentNumber = '';

    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];
      if (operators.contains(char)) {
        if (currentNumber.isNotEmpty) {
          // Format số trước khi thêm vào
          parts.add(TFormatter.formatVietnameseNumber(currentNumber));
          currentNumber = '';
        }
        // Thay * thành × cho đẹp hơn
        parts.add(char == '*' ? '×' : char);
      } else {
        currentNumber += char;
      }
    }

    // Thêm số cuối cùng nếu có
    if (currentNumber.isNotEmpty) {
      parts.add(TFormatter.formatVietnameseNumber(currentNumber));
    }

    return parts.join(' ');
  }

  /// Lấy text hiển thị cho nút ngày
  String _getDateText() {
    if (widget.selectedDate == null) {
      return 'Hôm nay';
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final selectedDateOnly = DateTime(
      widget.selectedDate!.year,
      widget.selectedDate!.month,
      widget.selectedDate!.day,
    );

    // Nếu là hôm nay thì hiển thị "Hôm nay"
    if (selectedDateOnly == todayOnly) {
      return 'Hôm nay';
    }

    // Format ngày theo định dạng dd/MM
    return '${widget.selectedDate!.day.toString().padLeft(2, '0')}/${widget.selectedDate!.month.toString().padLeft(2, '0')}';
  }
}
