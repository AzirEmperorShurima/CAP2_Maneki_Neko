import 'package:finance_management_app/common/api_builder/transaction_builder.dart';
import 'package:finance_management_app/common/widgets/text/price_text.dart';
import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/features/domain/entities/transaction_model.dart';
import 'package:finance_management_app/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:table_calendar/table_calendar.dart';

class TransactionCalendarBottomSheet extends StatefulWidget {
  const TransactionCalendarBottomSheet({super.key});

  static Future<void> show({required BuildContext context}) {
    return TLoaders.bottomSheet(
      context: context,
      heightPercentage: 0.85,
      borderRadius: AppBorderRadius.xlTop,
      child: const TransactionCalendarBottomSheet(),
    );
  }

  @override
  State<TransactionCalendarBottomSheet> createState() =>
      _TransactionCalendarBottomSheetState();
}

class _TransactionCalendarBottomSheetState
    extends State<TransactionCalendarBottomSheet> {
  late DateTime _focusedDate;
  DateTime? _selectedDate;
  String? _selectedType; // null = all, 'expense' = expenses, 'income' = income

  // Map to store transactions by date
  final Map<DateTime, List<TransactionModel>> _transactionsByDate = {};

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    _selectedDate = DateTime.now();
  }

  DateTime _getEndDateOfMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  }

  String _formatMonthYear(DateTime date) {
    return 'tháng ${date.month} năm ${date.year}';
  }

  void _onPreviousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
    });
  }

  void _onNextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
    });
  }

  void _onDateSelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
      _focusedDate = focusedDay;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDate = focusedDay;
    });
  }

  void _onTypeFilterChanged(String? type) {
    setState(() {
      _selectedType = type;
    });
  }

  double _calculateTotalExpense(List<TransactionModel> transactions) {
    return transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + (t.amount?.toDouble() ?? 0));
  }

  double _calculateTotalIncome(List<TransactionModel> transactions) {
    return transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + (t.amount?.toDouble() ?? 0));
  }

  double _calculateTotal(List<TransactionModel> transactions) {
    return _calculateTotalIncome(transactions) -
        _calculateTotalExpense(transactions);
  }

  List<TransactionModel> _getFilteredTransactions(
      List<TransactionModel> transactions) {
    if (_selectedType == null) return transactions;
    return transactions.where((t) => t.type == _selectedType).toList();
  }

  double _getTotalAmountForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final transactions = _transactionsByDate[day] ?? [];
    final filtered = _getFilteredTransactions(transactions);
    
    if (_selectedType == 'expense') {
      return _calculateTotalExpense(filtered);
    } else if (_selectedType == 'income') {
      return _calculateTotalIncome(filtered);
    } else {
      // Nếu là "Toàn bộ", hiển thị net (thu nhập - chi tiêu)
      return _calculateTotalIncome(filtered) - _calculateTotalExpense(filtered);
    }
  }

  String _formatShortAmount(double amount) {
    if (amount == 0) return '';
    final absAmount = amount.abs();
    
    if (absAmount >= 1000000) {
      // Triệu
      final millions = absAmount / 1000000;
      if (millions % 1 == 0) {
        return '${millions.toInt()}M';
      } else {
        return '${millions.toStringAsFixed(1)}M';
      }
    } else if (absAmount >= 1000) {
      // Nghìn
      final thousands = absAmount / 1000;
      if (thousands % 1 == 0) {
        return '${thousands.toInt()}k';
      } else {
        return '${thousands.toStringAsFixed(1)}k';
      }
    } else {
      return absAmount.toInt().toString();
    }
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthEnd = _getEndDateOfMonth(_focusedDate);

    return Column(
      children: [
        // Header
        Padding(
          padding: AppPadding.h16.add(AppPadding.v8),
          child: Row(
            children: [
              // Previous month arrow
              IconButton(
                onPressed: _onPreviousMonth,
                icon: const Icon(Iconsax.arrow_left_2, color: TColors.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              AppSpacing.w16,
              // Month/Year text
              Expanded(
                child: Text(
                  _formatMonthYear(_focusedDate),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              AppSpacing.w16,
              // Next month arrow
              IconButton(
                onPressed: _onNextMonth,
                icon: const Icon(Iconsax.arrow_right_3, color: TColors.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              AppSpacing.w8,
              // Month button
              Container(
                padding: AppPadding.h12.add(AppPadding.v8),
                decoration: BoxDecoration(
                  color: TColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Month',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: TColors.white,
                      ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.h8,

        // Calendar
        Expanded(
          child: TransactionBuilder(
            key: ValueKey(
                'calendar_${_focusedDate.year}_${_focusedDate.month}_$_selectedType'),
            type: _selectedType,
            page: 1,
            limit: 1000,
            month: monthEnd,
            autoLoad: true,
            disableScroll: true,
            onLoaded: (transactions) {
              // Group transactions by date
              _transactionsByDate.clear();
              for (final t in transactions) {
                if (t.date == null) continue;
                final day = DateTime(t.date!.year, t.date!.month, t.date!.day);
                _transactionsByDate.putIfAbsent(day, () => []).add(t);
              }
              setState(() {});
            },
            builder: (context, transactions) {
              // Group transactions by date for calendar display
              final allTransactions = transactions;
              final filteredTransactions = _getFilteredTransactions(allTransactions);

              // Calculate totals
              final totalExpense = _calculateTotalExpense(filteredTransactions);
              final totalIncome = _calculateTotalIncome(filteredTransactions);
              final total = _calculateTotal(filteredTransactions);

              return Column(
                children: [
                  // Calendar widget
                  Expanded(
                    child: Container(
                      margin: AppPadding.h16,
                      padding: AppPadding.a8,
                      decoration: BoxDecoration(
                        color: isDark ? TColors.darkContainer : TColors.white,
                        borderRadius: AppBorderRadius.md,
                      ),
                      child: TableCalendar(
                        firstDay: DateTime(2000),
                        lastDay: DateTime(2100),
                        focusedDay: _focusedDate,
                        selectedDayPredicate: (day) {
                          return _selectedDate != null &&
                              isSameDay(_selectedDate, day);
                        },
                        onDaySelected: _onDateSelected,
                        onPageChanged: _onPageChanged,
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.sunday,
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, date, _) {
                            final day = DateTime(date.year, date.month, date.day);
                            final totalAmount = _getTotalAmountForDate(day);
                            final isSelected = _selectedDate != null &&
                                isSameDay(_selectedDate, day);
                            final isWeekend = _isWeekend(date);
                            final shortAmount = _formatShortAmount(totalAmount);
                            final hasAmount = totalAmount != 0;

                            return Container(
                              margin: const EdgeInsets.all(1.5),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? TColors.primary
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${date.day}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isSelected
                                                  ? TColors.white
                                                  : (isWeekend
                                                      ? Colors.red
                                                      : null),
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                      ),
                                    ),
                                  ),
                                  if (hasAmount && !isSelected)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: Text(
                                        shortAmount,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: _selectedType == 'expense'
                                                  ? Colors.red
                                                  : (_selectedType == 'income'
                                                      ? Colors.green
                                                      : (totalAmount > 0
                                                          ? Colors.green
                                                          : Colors.red)),
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  else if (!hasAmount && !isSelected)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 0.5),
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '0',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: TColors.white,
                                                  fontSize: 7,
                                                  fontWeight: FontWeight.bold,
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
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: TColors.primary.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: TColors.primary,
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle:
                              Theme.of(context).textTheme.bodyMedium!,
                          weekendTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: Colors.red),
                          selectedTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: TColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                          todayTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: TColors.primary),
                          outsideDaysVisible: false,
                        ),
                        headerVisible: false,
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: Theme.of(context).textTheme.bodySmall!,
                          weekendStyle: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.h16,

                  // Filter buttons
                  Padding(
                    padding: AppPadding.h16,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFilterButton(
                            context,
                            label: 'Chi phí',
                            isSelected: _selectedType == 'expense',
                            onTap: () => _onTypeFilterChanged('expense'),
                          ),
                        ),
                        AppSpacing.w8,
                        Expanded(
                          child: _buildFilterButton(
                            context,
                            label: 'Thu nhập',
                            isSelected: _selectedType == 'income',
                            onTap: () => _onTypeFilterChanged('income'),
                          ),
                        ),
                        AppSpacing.w8,
                        Expanded(
                          child: _buildFilterButton(
                            context,
                            label: 'Toàn bộ',
                            isSelected: _selectedType == null,
                            onTap: () => _onTypeFilterChanged(null),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h16,

                  // Summary footer
                  Container(
                    padding: AppPadding.v16.add(AppPadding.h16),
                    decoration: BoxDecoration(
                      color: isDark ? TColors.darkContainer : TColors.softGrey,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppBorderRadius.md.topLeft.x),
                        topRight:
                            Radius.circular(AppBorderRadius.md.topRight.x),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          context,
                          amount: total.toString(),
                          label: 'Toàn bộ',
                          color: Colors.red,
                        ),
                        _buildSummaryItem(
                          context,
                          amount: totalIncome.toString(),
                          label: 'Thu nhập',
                          color: Colors.green,
                        ),
                        _buildSummaryItem(
                          context,
                          amount: totalExpense.toString(),
                          label: 'Chi tiêu',
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loadingBuilder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
            emptyBuilder: (context) {
              return Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: AppPadding.h16,
                      padding: AppPadding.a8,
                      decoration: BoxDecoration(
                        color: isDark ? TColors.darkContainer : TColors.white,
                        borderRadius: AppBorderRadius.md,
                      ),
                      child: TableCalendar(
                        firstDay: DateTime(2000),
                        lastDay: DateTime(2100),
                        focusedDay: _focusedDate,
                        selectedDayPredicate: (day) {
                          return _selectedDate != null &&
                              isSameDay(_selectedDate, day);
                        },
                        onDaySelected: _onDateSelected,
                        onPageChanged: _onPageChanged,
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.sunday,
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: TColors.primary.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: TColors.primary,
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle:
                              Theme.of(context).textTheme.bodyMedium!,
                          weekendTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: Colors.red),
                          selectedTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: TColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                          todayTextStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: TColors.primary),
                          outsideDaysVisible: false,
                        ),
                        headerVisible: false,
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: Theme.of(context).textTheme.bodySmall!,
                          weekendStyle: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.h16,
                  Padding(
                    padding: AppPadding.h16,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFilterButton(
                            context,
                            label: 'Chi phí',
                            isSelected: _selectedType == 'expense',
                            onTap: () => _onTypeFilterChanged('expense'),
                          ),
                        ),
                        AppSpacing.w8,
                        Expanded(
                          child: _buildFilterButton(
                            context,
                            label: 'Thu nhập',
                            isSelected: _selectedType == 'income',
                            onTap: () => _onTypeFilterChanged('income'),
                          ),
                        ),
                        AppSpacing.w8,
                        Expanded(
                          child: _buildFilterButton(
                            context,
                            label: 'Toàn bộ',
                            isSelected: _selectedType == null,
                            onTap: () => _onTypeFilterChanged(null),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h16,
                  Container(
                    padding: AppPadding.v16.add(AppPadding.h16),
                    decoration: BoxDecoration(
                      color: isDark ? TColors.darkContainer : TColors.softGrey,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppBorderRadius.md.topLeft.x),
                        topRight:
                            Radius.circular(AppBorderRadius.md.topRight.x),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          context,
                          amount: '0',
                          label: 'Toàn bộ',
                          color: Colors.red,
                        ),
                        _buildSummaryItem(
                          context,
                          amount: '0',
                          label: 'Thu nhập',
                          color: Colors.green,
                        ),
                        _buildSummaryItem(
                          context,
                          amount: '0',
                          label: 'Chi tiêu',
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppPadding.v8.add(AppPadding.h16),
        decoration: BoxDecoration(
          color: isSelected
              ? TColors.primary.withOpacity(0.2)
              : TColors.softGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TColors.primary,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String amount,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        PriceText(
          amount: amount,
          color: color,
        ),
        AppSpacing.h4,
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

