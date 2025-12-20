import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:table_calendar/table_calendar.dart';

/// Widget tái sử dụng để hiển thị date picker trong bottom sheet
class DatePickerBottomSheet extends StatefulWidget {
  /// Ngày ban đầu được chọn
  final DateTime initialDate;

  /// Callback khi ngày được chọn (gọi mỗi khi chọn ngày mới)
  final Function(DateTime)? onDateSelected;

  /// Callback khi xác nhận chọn ngày (gọi khi ấn nút tick)
  final Function(DateTime)? onConfirm;

  /// Chiều cao của bottom sheet (tỷ lệ với màn hình, mặc định 0.6)
  final double heightPercentage;

  /// Không cho phép chọn các ngày lớn hơn ngày hiện tại và làm mờ chúng
  final bool disableFutureDates;

  const DatePickerBottomSheet({
    super.key,
    required this.initialDate,
    this.onDateSelected,
    this.onConfirm,
    this.heightPercentage = 0.5,
    this.disableFutureDates = false,
  });

  /// Hàm helper để hiển thị date picker bottom sheet
  static Future<void> show({
    required BuildContext context,
    required DateTime initialDate,
    Function(DateTime)? onDateSelected,
    Function(DateTime)? onConfirm,
    double heightPercentage = 0.5,
    bool disableFutureDates = false,
  }) {
    return TLoaders.bottomSheet(
      context: context,
      heightPercentage: heightPercentage,
      borderRadius: AppBorderRadius.md,
      child: DatePickerBottomSheet(
        initialDate: initialDate,
        onDateSelected: onDateSelected,
        onConfirm: onConfirm,
        heightPercentage: heightPercentage,
        disableFutureDates: disableFutureDates,
      ),
    );
  }

  @override
  State<DatePickerBottomSheet> createState() => _DatePickerBottomSheetState();
}

class _DatePickerBottomSheetState extends State<DatePickerBottomSheet> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _focusedDate = widget.initialDate;
  }

  void _handleTodayPressed() {
    setState(() {
      _focusedDate = DateTime.now();
      _selectedDate = DateTime.now();
    });
    widget.onDateSelected?.call(_selectedDate);
  }

  void _handleDateSelected(DateTime selectedDay, DateTime focusedDay) {
    // Kiểm tra nếu disableFutureDates và ngày được chọn là tương lai
    if (widget.disableFutureDates) {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final selectedDayOnly =
          DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

      if (selectedDayOnly.isAfter(todayOnly)) {
        return; // Không cho phép chọn ngày tương lai
      }
    }

    setState(() {
      _selectedDate = selectedDay;
      _focusedDate = focusedDay;
    });
    widget.onDateSelected?.call(_selectedDate);
  }

  void _handlePageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDate = focusedDay;
    });
  }

  void _handleConfirm() {
    widget.onConfirm?.call(_selectedDate);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: AppPadding.h8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _handleTodayPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: TColors.white,
                  padding: AppPadding.h12,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.sm,
                  ),
                ),
                child: Text(
                  'HÔM NAY',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: TColors.white),
                ),
              ),
              IconButton(
                onPressed: _handleConfirm,
                icon: const Icon(
                  Iconsax.tick_square,
                  color: TColors.primary,
                  size: 28,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        AppSpacing.h8,
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: TColors.white,
              borderRadius: AppBorderRadius.md,
              border: Border.all(color: TColors.grey),
            ),
            padding: AppPadding.h8,
            margin: AppPadding.h8,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: AppPadding.h8,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _focusedDate = DateTime(
                              _focusedDate.year,
                              _focusedDate.month - 1,
                            );
                          });
                        },
                        icon: const Icon(Icons.chevron_left, size: 28),
                      ),
                    ),
                    Text(
                      'Tháng ${_focusedDate.month} ${_focusedDate.year}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Padding(
                      padding: AppPadding.h8,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _focusedDate = DateTime(
                              _focusedDate.year,
                              _focusedDate.month + 1,
                            );
                          });
                        },
                        icon: const Icon(Icons.chevron_right, size: 28),
                      ),
                    ),
                  ],
                ),
                AppSpacing.h8,
                Expanded(
                  child: TableCalendar(
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2100),
                  focusedDay: _focusedDate,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDate, day);
                  },
                  enabledDayPredicate: (day) {
                    return true;
                  },
                  onDaySelected: _handleDateSelected,
                  onPageChanged: _handlePageChanged,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, date, _) {
                      if (widget.disableFutureDates) {
                        final today = DateTime.now();
                        final todayOnly =
                            DateTime(today.year, today.month, today.day);
                        final dateOnly = DateTime(date.year, date.month, date.day);
              
                        if (dateOnly.isAfter(todayOnly)) {
                          // Làm mờ các ngày tương lai
                          return Center(
                            child: Text(
                              '${date.day}',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: TColors.darkGrey,
                                  ),
                            ),
                          );
                        }
                      }
                      return null; // Sử dụng style mặc định
                    },
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: TColors.primary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: TColors.primary,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
                    weekendTextStyle: Theme.of(context).textTheme.bodyMedium!,
                    selectedTextStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: TColors.white),
                    todayTextStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: TColors.primary),
                    disabledTextStyle:
                        Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: TColors.grey.withValues(alpha: 0.4),
                            ),
                    disabledDecoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                  ),
                  headerVisible: false,
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: Theme.of(context).textTheme.bodySmall!,
                    weekendStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: TColors.primary,
                        ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
