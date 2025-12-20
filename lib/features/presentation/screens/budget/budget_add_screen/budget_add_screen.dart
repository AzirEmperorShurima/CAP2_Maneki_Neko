import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/containers/bordered_container.dart';
import '../../../../../common/widgets/containers/bordered_text_field.dart';
import '../../../../../constants/app_border_radius.dart';
import '../../../../../constants/app_padding.dart';
import '../../../../../constants/app_spacing.dart';
import '../../../../../constants/colors.dart';
import '../../../../../features/domain/entities/budget_model.dart';
import '../../../../../features/presentation/blocs/budget/budget_bloc.dart';
import '../../../../../utils/popups/loaders.dart';

@RoutePage()
class BudgetAddScreen extends StatefulWidget {
  final BudgetModel? budget;

  const BudgetAddScreen({
    super.key,
    this.budget,
  });

  @override
  State<BudgetAddScreen> createState() => _BudgetAddScreenState();
}

class _BudgetAddScreenState extends State<BudgetAddScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  String? _selectedType;
  bool get _isEditMode => widget.budget != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // Pre-fill data khi edit
      nameController.text = widget.budget?.name ?? '';
      balanceController.text = widget.budget?.amount?.toString() ?? '';
      _selectedType = widget.budget?.type;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (balanceController.text.trim().isEmpty) {
      TLoaders.showNotification(
        context,
        type: NotificationType.error,
        title: 'Lỗi',
        message: 'Vui lòng nhập số tiền ngân sách',
      );
      return;
    }

    final amount = num.tryParse(balanceController.text.trim());
    if (amount == null || amount <= 0) {
      TLoaders.showNotification(
        context,
        type: NotificationType.error,
        title: 'Lỗi',
        message: 'Số tiền không hợp lệ',
      );
      return;
    }

    if (_isEditMode) {
      // Update budget - chỉ update amount
      context.read<BudgetBloc>().add(
            UpdateBudgetSubmitted(
              budgetId: widget.budget!.id!,
              amount: amount,
            ),
          );
    } else {
      // Create budget - cần đầy đủ thông tin
      if (nameController.text.trim().isEmpty) {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Lỗi',
          message: 'Vui lòng nhập tên ngân sách',
        );
        return;
      }

      if (_selectedType == null) {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Lỗi',
          message: 'Vui lòng chọn loại kỳ',
        );
        return;
      }

      context.read<BudgetBloc>().add(
            CreateBudgetSubmitted(
              name: nameController.text.trim(),
              type: _selectedType,
              amount: amount,
              updateIfExists: false,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BudgetBloc, BudgetState>(
      listener: (context, state) {
        if (state is BudgetCreated) {
          TLoaders.showNotification(
            context,
            type: NotificationType.success,
            title: 'Thành công',
            message: 'Tạo ngân sách thành công',
          );
          context.read<BudgetBloc>().add(RefreshBudgets());
          Navigator.of(context).pop();
        } else if (state is BudgetCreateFailure) {
          TLoaders.showNotification(
            context,
            type: NotificationType.error,
            title: 'Lỗi',
            message: state.message,
          );
        } else if (state is BudgetUpdated) {
          TLoaders.showNotification(
            context,
            type: NotificationType.success,
            title: 'Thành công',
            message: 'Cập nhật ngân sách thành công',
          );
          context.read<BudgetBloc>().add(RefreshBudgets());
          Navigator.of(context).pop();
        } else if (state is BudgetUpdateFailure) {
          TLoaders.showNotification(
            context,
            type: NotificationType.error,
            title: 'Lỗi',
            message: state.message,
          );
        }
      },
      child: Scaffold(
        appBar: TAppBar(
          title: Text(
            _isEditMode ? 'Chỉnh sửa ngân sách' : 'Thêm ngân sách',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: TColors.white),
          ),
          centerTitle: true,
          showBackArrow: true,
          leadingIconColor: TColors.white,
          backgroundColor: TColors.primary,
          actions: [
            BlocBuilder<BudgetBloc, BudgetState>(
              builder: (context, state) {
                final isLoading = state is BudgetCreating || state is BudgetUpdating;
                return IconButton(
                  onPressed: isLoading ? null : _handleSubmit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(TColors.white),
                          ),
                        )
                      : const Icon(Icons.check, size: 25, color: TColors.white),
                );
              },
            ),
          ],
        ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppPadding.a8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.h8,
              if (!_isEditMode) ...[
                BorderedTextField(
                  title: 'Tên ngân sách',
                  hintText: 'Nhập tên ngân sách',
                  controller: nameController,
                  assetIcon: 'assets/images/icons/budget.png',
                  isRequired: true,
                  borderRadius: 8,
                ),
                AppSpacing.h16,
              ] else ...[
                // Hiển thị thông tin budget khi edit (read-only)
                BorderedContainer(
                  padding: const EdgeInsets.only(
                      left: 16, right: 8, top: 16, bottom: 16),
                  child: Row(
                    children: [
                      Image.asset('assets/images/icons/budget.png',
                          height: 40, width: 40),
                      AppSpacing.w16,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tên ngân sách',
                                style: Theme.of(context).textTheme.titleLarge),
                            AppSpacing.h4,
                            Text(
                              widget.budget?.name ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.h16,
                BorderedContainer(
                  padding: const EdgeInsets.only(
                      left: 16, right: 8, top: 16, bottom: 16),
                  child: Row(
                    children: [
                      Image.asset('assets/images/icons/calendar.png',
                          height: 40, width: 40),
                      AppSpacing.w16,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Loại kỳ',
                                style: Theme.of(context).textTheme.titleLarge),
                            AppSpacing.h4,
                            Text(
                              _getTypeLabel(widget.budget?.type ?? ''),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.h16,
              ],
              BorderedTextField(
                title: 'Số tiền ngân sách',
                hintText: 'Nhập số tiền ngân sách',
                controller: balanceController,
                assetIcon: 'assets/images/icons/money.png',
                isRequired: true,
                borderRadius: 8,
              ),
              if (!_isEditMode) ...[
                AppSpacing.h16,
                BorderedContainer(
                  padding: const EdgeInsets.only(
                      left: 16, right: 8, top: 16, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/images/icons/select_icon.png',
                              height: 40, width: 40),
                          AppSpacing.w16,
                          Text('Biểu tượng',
                              style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                      const Icon(Icons.arrow_right,
                          size: 30, color: TColors.primary),
                    ],
                  ),
                ),
                AppSpacing.h16,
                GestureDetector(
                  onTap: () => showPeriodPickerBottomSheet(context),
                  child: BorderedContainer(
                    padding: const EdgeInsets.only(
                        left: 16, right: 8, top: 16, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/images/icons/calendar.png',
                                height: 40, width: 40),
                            AppSpacing.w16,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Loại kỳ',
                                    style: Theme.of(context).textTheme.titleLarge),
                                if (_selectedType != null) ...[
                                  AppSpacing.h4,
                                  Text(
                                    _getTypeLabel(_selectedType!),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_right,
                            size: 30, color: TColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ));
  }

  void showPeriodPickerBottomSheet(BuildContext context) {
    TLoaders.bottomSheet(
      context: context,
      heightPercentage: 0.3,
      borderRadius: AppBorderRadius.md,
      child: Column(
        children: [
          Text('Chọn loại kỳ', style: Theme.of(context).textTheme.titleLarge),
          Divider(color: TColors.grey.withOpacity(0.5)),
          Padding(
            padding: AppPadding.v8.add(AppPadding.h16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = 'daily';
                    });
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: AppPadding.v8,
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Text('Hằng ngày', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(color: TColors.grey.withOpacity(0.5)),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = 'monthly';
                    });
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: AppPadding.v8,
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Text('Hằng tháng', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(color: TColors.grey.withOpacity(0.5)),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = 'yearly';
                    });
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: AppPadding.v8,
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Text('Hằng năm', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                  ),
                ),
              ]
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'daily':
        return 'Hằng ngày';
      case 'monthly':
        return 'Hằng tháng';
      case 'yearly':
        return 'Hằng năm';
      default:
        return type;
    }
  }
}
