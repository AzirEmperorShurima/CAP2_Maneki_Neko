import 'package:auto_route/auto_route.dart';
import 'package:finance_management_app/common/widgets/appbar/home_appbar.dart';
import 'package:finance_management_app/common/widgets/profile/t_circular_image.dart';
import 'package:finance_management_app/common/widgets/text/price_text.dart';
import 'package:finance_management_app/common/widgets/wallet/create_first_wallet_dialog.dart';
import 'package:finance_management_app/constants/app_border_radius.dart';
import 'package:finance_management_app/constants/app_padding.dart';
import 'package:finance_management_app/constants/app_spacing.dart';
import 'package:finance_management_app/constants/colors.dart';
import 'package:finance_management_app/constants/image_strings.dart';
import 'package:finance_management_app/features/presentation/blocs/user/user_bloc.dart';
import 'package:finance_management_app/features/presentation/blocs/wallet/wallet_bloc.dart';
import 'package:finance_management_app/utils/helpers/helper_functions.dart';
import 'package:finance_management_app/utils/responsive/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/api_builder/analysis_builder.dart';
import '../../../../common/api_builder/budget_builder.dart';
import '../../../../common/api_builder/transaction_builder.dart';
import '../../../../common/widgets/card/budget_card.dart';
import '../../../../common/widgets/card/transaction_card.dart';
import '../../../../features/domain/entities/budget_model.dart';
import '../../../../features/domain/entities/transaction_model.dart';
import '../../../../utils/loaders/financial_card_loading.dart';
import '../../../../utils/utils.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedMonth;
  GlobalKey<AnalysisBuilderState> _analysisKey =
      GlobalKey<AnalysisBuilderState>();
  final PageController _budgetPageController = PageController();
  int _currentBudgetIndex = 0;
  int _budgetCount = 0;
  bool _isAmountHidden = false;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _loadAmountHiddenState();
    // Load wallets để kiểm tra
    context.read<WalletBloc>().add(LoadWalletsSubmitted());
  }

  Future<void> _loadAmountHiddenState() async {
    final isHidden = await Utils.getAmountHidden();
    if (mounted) {
      setState(() {
        _isAmountHidden = isHidden;
      });
    }
  }

  Future<void> _toggleAmountVisibility() async {
    final newState = !_isAmountHidden;
    await Utils.setAmountHidden(newState);
    if (mounted) {
      setState(() {
        _isAmountHidden = newState;
      });
    }
  }

  @override
  void dispose() {
    _budgetPageController.dispose();
    super.dispose();
  }

  void _startBudgetAutoScroll(int budgetCount) {
    if (budgetCount <= 1) return;

    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted &&
          _budgetPageController.hasClients &&
          _budgetCount == budgetCount) {
        _currentBudgetIndex = (_currentBudgetIndex + 1) % budgetCount;
        _budgetPageController.animateToPage(
          _currentBudgetIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startBudgetAutoScroll(budgetCount);
      }
    });
  }

  DateTime _getStartDateOfMonth(DateTime month) {
    return DateTime(month.year, month.month, 1);
  }

  DateTime _getEndDateOfMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  }

  /// Group transactions by date for UI display
  /// TransactionBuilder đã filter theo tháng rồi, chỉ cần group để hiển thị
  Map<DateTime, List<TransactionModel>> _groupTransactionsByDate(
      List<TransactionModel> transactions) {
    final grouped = <DateTime, List<TransactionModel>>{};
    for (final t in transactions) {
      if (t.date == null) continue;
      final day = DateTime(t.date!.year, t.date!.month, t.date!.day);
      grouped.putIfAbsent(day, () => []).add(t);
    }
    return grouped;
  }

  void _onPreviousMonth() {
    final newMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    setState(() {
      _selectedMonth = newMonth;
      _analysisKey = GlobalKey<AnalysisBuilderState>();
    });
  }

  void _onNextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (nextMonth.year < now.year ||
        (nextMonth.year == now.year && nextMonth.month <= now.month)) {
      setState(() {
        _selectedMonth = nextMonth;
        _analysisKey = GlobalKey<AnalysisBuilderState>();
      });
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = THelperFunctions.screenHeight(context);
    final screenWidth = THelperFunctions.screenWidth(context);
    final safeAreaTop = MediaQuery.of(context).padding.top;
    const appBarHeight = kToolbarHeight;

    final curvedContainerHeight =
        ResponsiveHelper.getResponsiveHeight(context, 0.11);
    final spacingAfterCurve =
        ResponsiveHelper.getResponsiveHeight(context, 0.10);
    final cardTopPosition = safeAreaTop +
        appBarHeight +
        curvedContainerHeight -
        ResponsiveHelper.getResponsiveHeight(context, 0.1);

    final isDark = THelperFunctions.isDarkMode(context);
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) async {
        // Kiểm tra nếu wallets được load và rỗng, hiển thị dialog hướng dẫn tạo ví
        if (state is WalletLoaded && state.wallets.isEmpty) {
          final hasShown = await Utils.getHasShownWalletDialog();
          if (!hasShown) {
            // Đánh dấu đã hiển thị
            await Utils.setHasShownWalletDialog(true);
            // Delay một chút để đảm bảo UI đã render xong
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                CreateFirstWalletDialog.show(context: context);
              }
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? TColors.dark : Colors.white,
        body: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
            Column(
              children: [
                Container(
                  color: TColors.primary,
                  child: const THomeAppBar(
                    backgroundColor: TColors.primary,
                  ),
                ),
                Container(
                  height: curvedContainerHeight,
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: TColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(
                              context, 0.18)),
                    ),
                  ),
                ),
                SizedBox(height: spacingAfterCurve),

                // List transactions với budget carousel ở đầu
                Expanded(
                  child: TransactionBuilder(
                    key: ValueKey(
                        'transaction_${_selectedMonth.year}_${_selectedMonth.month}'),
                    type: null,
                    page: 1,
                    limit: 20,
                    month: _getEndDateOfMonth(_selectedMonth),
                    onRefresh: () {
                      // Refresh AnalysisBuilder với đúng params ban đầu
                      _analysisKey.currentState?.refresh();
                    },
                    builder: (context, transactions) {
                      // TransactionBuilder đã filter theo tháng rồi (qua month parameter)
                      // Chỉ cần group để hiển thị UI
                      final grouped = _groupTransactionsByDate(transactions);
                      final dates = grouped.keys.toList()
                        ..sort((a, b) => b.compareTo(a));

                      return CustomScrollView(
                        slivers: [
                          // Budget carousel
                          SliverToBoxAdapter(
                            child: BudgetBuilder(
                              loadingBuilder: (context) {
                                return const SizedBox.shrink();
                              },
                              emptyBuilder: (context) {
                                return const SizedBox.shrink();
                              },
                              builder: (context, budgets) {
                                if (budgets.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                if (_budgetCount != budgets.length) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    setState(() {
                                      _budgetCount = budgets.length;
                                    });
                                    _startBudgetAutoScroll(budgets.length);
                                  });
                                }
                                return _buildBudgetCarousel(context, budgets);
                              },
                            ),
                          ),

                          // Transaction list
                          SliverPadding(
                            padding: const EdgeInsets.only(bottom: 100),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index >= dates.length) return null;

                                  final date = dates[index];
                                  final dayTransactions = grouped[date]!;
                                  final totalExpense = dayTransactions
                                      .where((t) =>
                                          t.type != null && t.type == 'expense')
                                      .fold(
                                          0.0,
                                          (sum, t) =>
                                              sum +
                                              (t.amount?.toDouble() ?? 0));

                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 500),
                                    child: SlideAnimation(
                                      verticalOffset: 50,
                                      child: FadeInAnimation(
                                        child: TransactionCard(
                                          date: date,
                                          transactions: dayTransactions,
                                          totalExpense: totalExpense,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: dates.length,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            // Financial card
            Positioned(
              top: cardTopPosition,
              left: 0,
              right: 0,
              child: Container(
                margin: AppPadding.h16,
                height: ResponsiveHelper.getResponsiveHeight(context, 0.19),
                decoration: BoxDecoration(
                  color: isDark ? TColors.darkContainer : Colors.white,
                  borderRadius: AppBorderRadius.md,
                  boxShadow: [
                    BoxShadow(
                      color: TColors.primary.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                padding: AppPadding.a8,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // User avatar
                        BlocBuilder<UserBloc, UserState>(
                          builder: (context, state) {
                            return state is UserLoaded
                                ? TCircularImage(
                                    image: state.user.avatar ?? TImages.user,
                                    isNetworkImage: state.user.avatar != null,
                                    height:
                                        ResponsiveHelper.getResponsiveHeight(
                                            context, 0.07),
                                    width: ResponsiveHelper.getResponsiveHeight(
                                        context, 0.07),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                        AppSpacing.w16,

                        // Month selector
                        Expanded(
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _onPreviousMonth,
                                child: const Icon(Icons.arrow_back_ios,
                                    size: 15, color: TColors.primary),
                              ),
                              AppSpacing.w16,
                              Row(
                                children: [
                                  Text(
                                    '${_selectedMonth.month.toString().padLeft(2, '0')}/${_selectedMonth.year}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  AppSpacing.w4,
                                  const Icon(Icons.arrow_drop_down,
                                      size: 20, color: TColors.primary),
                                ],
                              ),
                              AppSpacing.w8,
                              GestureDetector(
                                onTap: _onNextMonth,
                                child: const Icon(Icons.arrow_forward_ios,
                                    size: 15),
                              ),
                              const Spacer(),
                              const Icon(Iconsax.sms_notification, size: 25),
                            ],
                          ),
                        ),
                        AppSpacing.w8,
                        Container(
                          width: 1,
                          height: 20,
                          color: TColors.softGrey,
                        ),
                        AppSpacing.w8,
                        GestureDetector(
                          onTap: _toggleAmountVisibility,
                          child: Icon(
                            _isAmountHidden ? Iconsax.eye_slash : Iconsax.eye,
                            size: 25,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: TColors.softGrey),
                    AppSpacing.h8,

                    // Analysis overall
                    AnalysisBuilder(
                      key: _analysisKey,
                      autoLoad: true,
                      startDate: _getStartDateOfMonth(_selectedMonth),
                      endDate: _getEndDateOfMonth(_selectedMonth),
                      loadingBuilder: (context) {
                        return const FinancialItemsLoading();
                      },
                      builder: (context, analysis) {
                        final isNegative =
                            (analysis?.overall?.netBalance ?? 0) < 0;

                        (analysis?.overall?.netBalance ?? 0).toString();

                        final income =
                            (analysis?.overall?.income?.total ?? 0).toString();

                        final expense =
                            (analysis?.overall?.expense?.total ?? 0).toString();

                        final netBalance =
                            analysis?.overall?.netBalance?.toString() ?? '0';

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildFinancialItem(
                              context,
                              amount: netBalance,
                              label: 'Tổng',
                              icon: Iconsax.empty_wallet,
                              color: isNegative ? Colors.red : Colors.green,
                              title: isNegative ? '-' : null,
                            ),
                            _buildDivider(context),
                            _buildFinancialItem(
                              context,
                              amount: income,
                              label: 'Thu nhập',
                              icon: Iconsax.arrow_up_1,
                              color: Colors.green,
                            ),
                            _buildDivider(context),
                            _buildFinancialItem(
                              context,
                              amount: expense,
                              label: 'Chi tiêu',
                              icon: Iconsax.arrow_down_2,
                              color: Colors.red,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFinancialItem(
    BuildContext context, {
    required String amount,
    required String label,
    required IconData icon,
    required Color color,
    String? title,
  }) {
    final iconSize = ResponsiveHelper.getResponsiveIconSize(context, 0.015);

    final displayAmount = _isAmountHidden ? '****' : amount;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_isAmountHidden)
            Text(
              displayAmount,
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(color: color),
            )
          else
            PriceText(
              amount: amount,
              color: color,
              title: title,
            ),
          AppSpacing.h8,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize),
              AppSpacing.w4,
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: ResponsiveHelper.getResponsiveHeight(context, 0.037),
      color: TColors.softGrey,
    );
  }

  Widget _buildBudgetCarousel(BuildContext context, List<BudgetModel> budgets) {
    return Column(
      children: [
        SizedBox(
          height: ResponsiveHelper.getResponsiveHeight(context, 0.09),
          child: PageView.builder(
            controller: _budgetPageController,
            onPageChanged: (index) {
              setState(() => _currentBudgetIndex = index);
            },
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return Padding(
                padding: AppPadding.h16.add(AppPadding.v8),
                child: BudgetCard(
                  budget: budget,
                  variant: BudgetCardVariant.compact,
                ),
              );
            },
          ),
        ),

        /// --- DOT INDICATOR ---
        if (budgets.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              budgets.length,
              (index) {
                final isActive = index == _currentBudgetIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? TColors.primary : TColors.softGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
