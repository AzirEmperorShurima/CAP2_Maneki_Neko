import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/common/widgets/appbar/appbar.dart';
import 'package:finance_management_app/common/widgets/date_picker/date_picker_bottom_sheet.dart';
import 'package:finance_management_app/common/widgets/member_picker/member_picker_bottom_sheet.dart';
import 'package:finance_management_app/common/widgets/wallet_picker/wallet_picker_bottom_sheet.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/features/presentation/blocs/category/category_bloc.dart';
import 'package:finance_management_app/features/presentation/blocs/transaction/transaction_bloc.dart';
import 'package:finance_management_app/features/presentation/blocs/wallet/wallet_bloc.dart';
import 'package:finance_management_app/features/presentation/screens/transactions_add_screen/tabs/transactions_add_expense.dart';
import 'package:finance_management_app/features/presentation/screens/transactions_add_screen/tabs/transactions_add_income.dart';
import 'package:finance_management_app/features/presentation/screens/transactions_add_screen/tabs/transactions_add_transfer.dart';
import 'package:finance_management_app/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/category/create_category_bottom_sheet.dart';
import '../../../../common/widgets/custom_number_keyboard/custom_numeric_keyboard.dart';
import '../../../../common/widgets/tab_switcher/tab_switcher.dart';
import '../../../../constants/app_border_radius.dart';
import '../../../../constants/app_padding.dart';
import '../../../../utils/device/device_utility.dart';
import '../../../domain/entities/transaction_model.dart';
import '../../../domain/entities/wallet_model.dart';
import '../../blocs/analysis/analysis_bloc.dart';
import '../../blocs/budget/budget_bloc.dart';

@RoutePage()
class TransactionsAddScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const TransactionsAddScreen({super.key, this.transaction});

  @override
  State<TransactionsAddScreen> createState() => _TransactionsAddScreenState();
}

class _TransactionsAddScreenState extends State<TransactionsAddScreen> {
  late final PageController _pageController;

  int _selectedIndex = 0;

  String _amount = '0';

  String _note = '';

  String _expression = '0';

  bool _justCalculated = false;

  DateTime _selectedDate = DateTime.now();

  String? _selectedCategoryId;

  String? _selectedWalletId;

  String? _selectedMemberType = 'Tôi';

  String? _fromWalletId;
  String? _toWalletId;

  bool _shouldPopOnSuccess = true;
  String? _transactionId;

  void _loadCategoriesForTab(int index) {
    final categoryBloc = context.read<CategoryBloc>();
    String? type;

    if (index == 0) {
      type = 'expense';
    } else if (index == 1) {
      type = 'income';
    }

    if (type != null) {
      categoryBloc.add(LoadCategoriesSubmitted(type: type));
    }
  }

  String _getBudgetTitle(String? level) {
    switch (level) {
      case 'info':
        return 'Thông báo ngân sách';
      case 'warning':
        return 'Ngân sách sắp cao';
      case 'critical':
        return 'Gần vượt ngân sách';
      case 'error':
        return 'Vượt quá ngân sách';
      default:
        return 'Ngân sách';
    }
  }

  @override
  void initState() {
    super.initState();

    // Nếu có transaction (edit mode), load dữ liệu vào form
    if (widget.transaction != null) {
      final transaction = widget.transaction!;
      _transactionId = transaction.id;
      _amount = (transaction.amount ?? 0).toString();
      _expression = _amount;
      _note = transaction.description ?? '';
      _selectedDate = transaction.date ?? DateTime.now();
      _selectedCategoryId = transaction.category?.id;
      _selectedWalletId = transaction.wallet?.id;
      _selectedMemberType = transaction.expenseFor ?? 'Tôi';

      // Xác định tab dựa trên type
      if (transaction.type == 'expense') {
        _selectedIndex = 0;
      } else if (transaction.type == 'income') {
        _selectedIndex = 1;
      } else {
        _selectedIndex = 2;
      }
    }

    // Khởi tạo PageController với initialPage
    _pageController = PageController(initialPage: _selectedIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoriesForTab(_selectedIndex);
    });
  }

  void _createTransaction() {
    // Validate dữ liệu
    if (_amount == '0' || _amount.isEmpty) {
      TLoaders.showNotification(
        context,
        type: NotificationType.error,
        title: 'Lỗi',
        message: 'Vui lòng nhập số tiền',
      );
      return;
    }

    // ⛳ Validate ví cho Chi tiêu / Thu nhập
    if (_selectedIndex != 2) {
      if (_selectedWalletId == null || _selectedWalletId!.isEmpty) {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Lỗi',
          message: 'Vui lòng chọn ví',
        );
        return;
      }
    }

    if (_selectedIndex == 0 || _selectedIndex == 1) {
      if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Lỗi',
          message: 'Vui lòng chọn danh mục',
        );
      }
    }

    // Nếu là transfer, validate fromWallet và toWallet
    if (_selectedIndex == 2) {
      if (_fromWalletId == null || _fromWalletId!.isEmpty) {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Lỗi',
          message: 'Vui lòng chọn ví chuyển',
        );
        return;
      }
      if (_toWalletId == null || _toWalletId!.isEmpty) {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Lỗi',
          message: 'Vui lòng chọn ví nhận',
        );
        return;
      }
      if (_fromWalletId == _toWalletId) {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Lỗi',
          message: 'Ví chuyển và ví nhận không được giống nhau',
        );
        return;
      }
    } else {
      if (_selectedCategoryId == null) {
        TLoaders.showNotification(
          context,
          type: NotificationType.error,
          title: 'Lỗi',
          message: 'Vui lòng chọn danh mục',
        );
        return;
      }
    }

    // Parse amount
    final amount = double.tryParse(_amount);
    if (amount == null) {
      TLoaders.showNotification(
        context,
        type: NotificationType.error,
        title: 'Lỗi',
        message: 'Số tiền không hợp lệ',
      );
      return;
    }

    // Nếu là transfer, gọi transfer wallet
    if (_selectedIndex == 2) {
      context.read<WalletBloc>().add(
            TransferWalletSubmitted(
              fromWalletId: _fromWalletId,
              toWalletId: _toWalletId,
              amount: amount,
              note: _note.isEmpty ? '' : _note,
            ),
          );
      return;
    }

    // Xác định type dựa trên tab
    String? type;
    if (_selectedIndex == 0) {
      type = 'expense';
    } else if (_selectedIndex == 1) {
      type = 'income';
    }

    // Nếu có transactionId thì update, ngược lại thì create
    if (_transactionId != null && _transactionId!.isNotEmpty) {
      // Update transaction
      context.read<TransactionBloc>().add(
            UpdateTransactionSubmitted(
              transactionId: _transactionId!,
              type: type,
              amount: amount,
              description: _note.isEmpty ? '' : _note,
              categoryId: _selectedCategoryId,
              date: _selectedDate,
              walletId:
                  (_selectedWalletId == null || _selectedWalletId!.isEmpty)
                      ? ''
                      : _selectedWalletId,
              memberType:
                  (_selectedMemberType == null || _selectedMemberType!.isEmpty)
                      ? 'Tôi'
                      : _selectedMemberType,
            ),
          );
    } else {
      // Create transaction
      context.read<TransactionBloc>().add(
            CreateTransactionSubmitted(
              type: type,
              amount: amount,
              description: _note.isEmpty ? '' : _note,
              categoryId: _selectedCategoryId,
              date: _selectedDate,
              walletId:
                  (_selectedWalletId == null || _selectedWalletId!.isEmpty)
                      ? ''
                      : _selectedWalletId,
              memberType:
                  (_selectedMemberType == null || _selectedMemberType!.isEmpty)
                      ? 'Tôi'
                      : _selectedMemberType,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: TAppBar(
        leadingIcon: Iconsax.close_square,
        leadingIconColor: TColors.primary,
        leadingIconSize: 28,
        leadingOnPressed: () => Navigator.of(context).pop(),
        title: Text(
            widget.transaction != null ? 'Sửa giao dịch' : 'Thêm giao dịch',
            style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: true,
        actions: [
          BlocConsumer<WalletBloc, WalletState>(listener: (context, state) {
            if (state is WalletTransferred) {
              // Refresh danh sách transaction
              context.read<TransactionBloc>().add(
                    RefreshTransactions(
                      type: null,
                      page: 1,
                      limit: 20,
                    ),
                  );

              // Refresh analysis
              context.read<AnalysisBloc>().add(RefreshAnalysis());

              // Refresh wallet
              context.read<WalletBloc>().add(RefreshWallets());

              // Refresh budget
              context.read<BudgetBloc>().add(RefreshBudgets());

              TLoaders.showNotification(
                context,
                type: NotificationType.success,
                title: 'Thành công',
                message: 'Chuyển tiền thành công',
              );

              if (_shouldPopOnSuccess) {
                _shouldPopOnSuccess =
                    false; // Set false trước khi pop để tránh pop 2 lần
                // Delay pop để tránh conflict với các refresh operations
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                });
              }
            } else if (state is WalletTransferFailure) {
              TLoaders.showNotification(
                context,
                type: NotificationType.error,
                title: 'Lỗi',
                message: state.message,
              );

              _shouldPopOnSuccess = true;
            }
          }, builder: (context, walletState) {
            final isTransferring = walletState is WalletTransferring;
            return BlocConsumer<TransactionBloc, TransactionState>(
              listener: (context, state) {
                if (state is TransactionCreated ||
                    state is TransactionUpdated) {
                  final isUpdate = state is TransactionUpdated;
                  // Refresh danh sách transaction
                  context.read<TransactionBloc>().add(
                        RefreshTransactions(
                          type: null,
                          page: 1,
                          limit: 20,
                        ),
                      );

                  // Refresh analysis
                  context.read<AnalysisBloc>().add(RefreshAnalysis());

                  // Refresh wallet
                  context.read<WalletBloc>().add(RefreshWallets());

                  // Refresh budget
                  context.read<BudgetBloc>().add(RefreshBudgets());

                  // Thông báo thành công
                  TLoaders.showNotification(
                    context,
                    type: NotificationType.success,
                    title: 'Thành công',
                    message: isUpdate
                        ? 'Cập nhật giao dịch thành công'
                        : 'Tạo giao dịch thành công',
                  );

                  // ⛳ XỬ LÝ BUDGET WARNINGS
                  final budgetWarnings = isUpdate
                      ? (state as TransactionUpdated).budgetWarnings
                      : (state as TransactionCreated).budgetWarnings;
                  if (budgetWarnings != null &&
                      budgetWarnings.warnings != null &&
                      budgetWarnings.warnings!.isNotEmpty) {
                    for (final w in budgetWarnings.warnings!) {
                      // Map level → NotificationType
                      NotificationType notiType;
                      switch (w.level) {
                        case 'info':
                          notiType = NotificationType.info;
                          break;
                        case 'warning':
                          notiType = NotificationType.warning;
                          break;
                        case 'near_limit':
                          notiType = NotificationType.error;
                          break;
                        case 'over_budget':
                        default:
                          notiType = NotificationType.error;
                      }

                      // Gọi popup hiển thị cảnh báo
                      TLoaders.showNotification(
                        context,
                        timeDuration: 15,
                        type: notiType,
                        title: _getBudgetTitle(w.level),
                        message: w.message ?? '',
                      );
                    }
                  }

                  if (_shouldPopOnSuccess) {
                    _shouldPopOnSuccess =
                        false; // Set false trước khi pop để tránh pop 2 lần
                    // Delay pop để tránh conflict với các refresh operations
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    });
                  }
                }

                // ⛳ lỗi tạo/cập nhật transaction
                else if (state is TransactionFailure ||
                    state is TransactionCreateFailure ||
                    state is TransactionUpdateFailure) {
                  TLoaders.showNotification(
                    context,
                    type: NotificationType.error,
                    title: 'Lỗi',
                    message: state is TransactionFailure
                        ? state.message
                        : state is TransactionCreateFailure
                            ? (state as TransactionCreateFailure).message
                            : (state as TransactionUpdateFailure).message,
                  );

                  _shouldPopOnSuccess = true;
                } else if (state is TransactionDeleted) {
                  // Refresh danh sách transaction
                  context.read<TransactionBloc>().add(
                        RefreshTransactions(
                          type: null,
                          page: 1,
                          limit: 20,
                        ),
                      );

                  // Refresh analysis
                  context.read<AnalysisBloc>().add(RefreshAnalysis());

                  // Refresh wallet
                  context.read<WalletBloc>().add(RefreshWallets());

                  // Refresh budget
                  context.read<BudgetBloc>().add(RefreshBudgets());
                }
              },
              builder: (context, transactionState) {
                final isCreating = transactionState is TransactionCreating;
                final isUpdating = transactionState is TransactionUpdating;
                final isLoading = isCreating || isUpdating || isTransferring;

                return IconButton(
                  onPressed: isLoading ? null : _createTransaction,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: TColors.primary,
                          ),
                        )
                      : const Icon(
                          Iconsax.tick_square,
                          size: 28,
                          color: TColors.primary,
                        ),
                );
              },
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          // Nội dung chính
          Column(
            children: [
              const Divider(),
              Expanded(
                child: Padding(
                  padding: AppPadding.h8,
                  child: Column(
                    children: [
                      AppSpacing.h4,
                      TabSwitcher(
                        tabs: const [
                          'Chi tiêu',
                          'Thu nhập',
                          'Chuyển tiền',
                        ],
                        padding: AppPadding.a8.add(AppPadding.a2),
                        selectedIndex: _selectedIndex,
                        onTabSelected: (index) {
                          TDeviceUtils.lightImpact();
                          setState(() => _selectedIndex = index);
                          _pageController.jumpToPage(index);
                          _loadCategoriesForTab(index);
                        },
                      ),
                      AppSpacing.h8,
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (value) {
                            setState(() => _selectedIndex = value);
                            _loadCategoriesForTab(value);
                          },
                          children: [
                            TransactionsAddExpense(
                              initialCategoryId: _selectedCategoryId,
                              onCategorySelected: (categoryId) {
                                setState(() {
                                  _selectedCategoryId = categoryId;
                                });
                              },
                            ),
                            TransactionsAddIncome(
                              initialCategoryId: _selectedCategoryId,
                              onCategorySelected: (categoryId) {
                                setState(() {
                                  _selectedCategoryId = categoryId;
                                });
                              },
                            ),
                            BlocBuilder<WalletBloc, WalletState>(
                              builder: (context, walletState) {
                                final wallets = walletState is WalletLoaded
                                    ? walletState.wallets
                                    : walletState is WalletRefreshing
                                        ? walletState.wallets
                                        : <WalletModel>[];
                                return TransactionsAddTransfer(
                                  fromWalletId: _fromWalletId,
                                  toWalletId: _toWalletId,
                                  amount: _amount,
                                  wallets: wallets,
                                  onFromWalletSelected: (walletId) {
                                    setState(() {
                                      _fromWalletId = walletId;
                                    });
                                  },
                                  onToWalletSelected: (walletId) {
                                    setState(() {
                                      _toWalletId = walletId;
                                    });
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bàn phím số
              BlocBuilder<WalletBloc, WalletState>(
                builder: (context, walletState) {
                  final isTransferring = walletState is WalletTransferring;
                  return BlocBuilder<TransactionBloc, TransactionState>(
                    builder: (context, transactionState) {
                      final isCreating =
                          transactionState is TransactionCreating;
                      final isLoading = isCreating || isTransferring;
                      return CustomNumericKeyboard(
                        amount: _amount,
                        note: _note,
                        selectedDate: _selectedDate,
                        isLoading: isLoading,
                        onNumberPressed: (number) {
                          setState(() {
                            if (_justCalculated) {
                              _expression = number;
                              _justCalculated = false;
                            } else if (_expression == '0' ||
                                _expression.isEmpty) {
                              _expression = number;
                            } else {
                              _expression += number;
                            }
                            _amount = _expression;
                          });
                        },
                        onBackspacePressed: () {
                          setState(() {
                            _justCalculated = false;
                            if (_expression.length > 1) {
                              _expression = _expression.substring(
                                  0, _expression.length - 1);
                            } else {
                              _expression = '0';
                            }
                            _amount = _expression;
                          });
                        },
                        onWalletPressed: () {
                          WalletPickerBottomSheet.show(
                            context: context,
                            selectedWalletId: _selectedWalletId,
                            onWalletSelected: (walletId) {
                              setState(() {
                                _selectedWalletId = walletId;
                              });
                            },
                          );
                        },
                        onNoteChanged: (note) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _note = note;
                              });
                            }
                          });
                        },
                        onDatePressed: () {
                          DatePickerBottomSheet.show(
                            context: context,
                            initialDate: _selectedDate,
                            onDateSelected: (date) {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                            onConfirm: (date) {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                            disableFutureDates: true,
                          );
                        },
                        onMemberPressed: () {
                          MemberPickerBottomSheet.show(
                            context: context,
                            selectedType: _selectedMemberType,
                            onMemberSelected: (type, typeName) {
                              setState(() {
                                _selectedMemberType = type;
                              });
                            },
                          );
                        },
                        onPlusPressed: () {
                          _shouldPopOnSuccess = false;
                          _createTransaction();
                        },
                        onCheckPressed: () {
                          _shouldPopOnSuccess = true;
                          _createTransaction();
                        },
                        onOperatorPressed: (operator) {
                          setState(() {
                            _justCalculated = false;
                            if (_expression.isNotEmpty &&
                                ['+', '-', '*', '/'].contains(
                                    _expression[_expression.length - 1])) {
                              _expression = _expression.substring(
                                      0, _expression.length - 1) +
                                  operator;
                            } else {
                              _expression += operator;
                            }
                            _amount = _expression;
                          });
                        },
                        onAmountCalculated: (result) {
                          setState(() {
                            _amount = result;
                            _expression = result;
                            _justCalculated = true;
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),

          // Nút + nổi - Tính toán khoảng cách động
          if (_selectedIndex == 0 || _selectedIndex == 1)
            Builder(
              builder: (context) {
                final viewInsets = MediaQuery.of(context).viewInsets.bottom;
                final keyboardHeight = viewInsets > 0 ? viewInsets : 0;
                // Ước tính chiều cao của CustomNumericKeyboard (khoảng 300-350px)
                const customKeyboardHeight = 300.0;
                // Khoảng cách an toàn
                const safePadding = 16.0;

                // Nếu có keyboard hệ thống (từ TextField), tính từ keyboard
                // Nếu không, tính từ bottom của CustomNumericKeyboard
                final bottomPosition = keyboardHeight > 0
                    ? keyboardHeight + safePadding
                    : customKeyboardHeight + safePadding;

                return Positioned(
                  right: 16,
                  bottom: bottomPosition,
                  child: GestureDetector(
                    onTap: () {
                      // Xác định type dựa trên tab hiện tại
                      String? categoryType;
                      if (_selectedIndex == 0) {
                        categoryType = 'expense';
                      } else if (_selectedIndex == 1) {
                        categoryType = 'income';
                      }

                      if (categoryType != null) {
                        CreateCategoryBottomSheet.show(
                          context: context,
                          type: categoryType,
                          onCategoryCreated: (category) {
                            // Cập nhật selectedCategoryId
                            setState(() {
                              _selectedCategoryId = category.id;
                            });
                            // Refresh category list
                            _loadCategoriesForTab(_selectedIndex);
                          },
                        );
                      }
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: TColors.primary,
                        borderRadius: AppBorderRadius.sm,
                      ),
                      child: const Icon(
                        Iconsax.add,
                        color: TColors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
