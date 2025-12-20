import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/text/overflow_marquee_text.dart';
import '../../../../../common/widgets/text/price_text.dart';
import '../../../../../constants/app_border_radius.dart';
import '../../../../../constants/app_padding.dart';
import '../../../../../constants/app_spacing.dart';
import '../../../../../constants/colors.dart';
import '../../../../../utils/helpers/category_icon_helper.dart';
import '../../../../domain/entities/family_top_categories_model.dart';
import '../../../blocs/family/family_bloc.dart';

class FamilyTopCategoriesTab extends StatefulWidget {
  const FamilyTopCategoriesTab({super.key});

  @override
  State<FamilyTopCategoriesTab> createState() => _FamilyTopCategoriesTabState();
}

class _FamilyTopCategoriesTabState extends State<FamilyTopCategoriesTab> {
  int touchedIndex = -1;
  FamilyTopCategoriesModel? _cachedData;

  static const List<Color> _categoryColors = [
    Colors.orange,
    Colors.pink,
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.teal,
    Colors.amber,
    Colors.red,
    Colors.indigo,
    Colors.grey,
  ];

  Color _getCategoryColor(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

  void _ensureDataLoaded() {
    if (_cachedData == null) {
      context.read<FamilyBloc>().add(LoadFamilyTopCategories());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyBloc, FamilyState>(
      builder: (context, state) {
        // Lưu lại data khi state là Loaded
        if (state is FamilyTopCategoriesLoaded) {
          _cachedData = state.categories;
        }

        // Nếu state không phải là state của tab này
        if (!(state is FamilyTopCategoriesLoading ||
            state is FamilyTopCategoriesLoaded ||
            state is FamilyTopCategoriesFailure)) {
          // Nếu đã có data cache, hiển thị data đó
          if (_cachedData != null) {
            return _buildContent(_cachedData!);
          }
          // Nếu chưa có data, dispatch event để load
          _ensureDataLoaded();
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FamilyTopCategoriesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FamilyTopCategoriesFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lỗi: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                ),
                AppSpacing.h16,
                ElevatedButton(
                  onPressed: () {
                    _cachedData = null;
                    context.read<FamilyBloc>().add(LoadFamilyTopCategories());
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (state is FamilyTopCategoriesLoaded) {
          final categories = state.categories;
          if (categories == null) {
            return const Center(
              child: Text('Không có dữ liệu'),
            );
          }

          return _buildContent(categories);
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildContent(FamilyTopCategoriesModel categories) {
    return SingleChildScrollView(
      padding: AppPadding.a16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          if (categories.summary != null)
            _buildSummaryCard(context, categories.summary!),
          AppSpacing.h16,

          // Pie Chart
          if (categories.chart != null)
            _buildPieChartCard(context, categories.chart!),
          AppSpacing.h16,

          // Categories List
          if (categories.categories != null &&
              categories.categories!.isNotEmpty) ...[
            _buildSectionTitle(context, 'Danh sách danh mục'),
            AppSpacing.h8,
            ...categories.categories!.map((category) => Padding(
                  padding: AppPadding.v4,
                  child: _buildCategoryCard(context, category),
                )),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, FamilyTopCategoriesSummaryModel summary) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.md,
        color: TColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: AppPadding.a16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.h16,
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Tổng tiền',
                  summary.total ?? 0,
                  TColors.primary,
                ),
              ),
              AppSpacing.w8,
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Giao dịch',
                  summary.count?.toDouble() ?? 0,
                  Colors.blue,
                  isCount: true,
                ),
              ),
            ],
          ),
          AppSpacing.h8,
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Danh mục',
                  summary.categoryCount?.toDouble() ?? 0,
                  Colors.green,
                  isCount: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double value,
    Color color, {
    bool isCount = false,
  }) {
    return Container(
      padding: AppPadding.a8,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppBorderRadius.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TColors.darkerGrey,
                ),
          ),
          AppSpacing.h4,
          if (isCount)
            Text(
              value.toInt().toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            )
          else
            PriceText(
              amount: value.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(
    BuildContext context,
    FamilyTopCategoriesChartModel chart,
  ) {
    if (chart.data == null || chart.data!.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: AppBorderRadius.md,
          color: TColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: AppPadding.a16,
        child: Center(
          child: Text(
            'Không có dữ liệu',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.md,
        color: TColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: AppPadding.a16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chart.title ?? 'Top danh mục chi tiêu',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppSpacing.h16,
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _buildPieChartSections(context, chart.data!),
              ),
            ),
          ),
          AppSpacing.h16,
          // Legend
          ...chart.data!.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isTouched = touchedIndex == index;
            return Padding(
              padding: AppPadding.v4,
              child: _buildLegendItem(context, item, index, isTouched),
            );
          }),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    BuildContext context,
    List<FamilyTopCategoryChartItemModel> data,
  ) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = touchedIndex == index;
      final radius = isTouched ? 70.0 : 60.0;
      final percentage = item.percentage ?? 0.0;
      final categoryName = item.name ?? 'Khác';
      final iconPath = CategoryIconHelper.getIconPath(
        categoryName,
        'expense',
      );

      return PieChartSectionData(
        color: _getCategoryColor(index),
        value: item.value ?? 0,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: TColors.white),
        badgeWidget: Image.asset(
          iconPath,
          width: 25,
          height: 25,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Iconsax.more,
              size: 25,
              color: _getCategoryColor(index),
            );
          },
        ),
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildLegendItem(
    BuildContext context,
    FamilyTopCategoryChartItemModel item,
    int index,
    bool isTouched,
  ) {
    final percentage = item.percentage ?? 0.0;
    final value = item.value ?? 0.0;
    final categoryName = item.name ?? 'Khác';
    final iconPath = CategoryIconHelper.getIconPath(categoryName, 'expense');

    return Container(
      padding: AppPadding.v8,
      decoration: BoxDecoration(
        color: isTouched
            ? _getCategoryColor(index).withOpacity(0.2)
            : Colors.transparent,
        borderRadius: AppBorderRadius.sm,
      ),
      child: Row(
        children: [
          // Icon
          SizedBox(
            width: 24,
            height: 24,
            child: Image.asset(
              iconPath,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: _getCategoryColor(index),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.more,
                    size: 16,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),

          AppSpacing.w8,

          // Tên
          Expanded(
            flex: 3,
            child: OverflowMarqueeText(
              text: categoryName,
              style: Theme.of(context).textTheme.bodyMedium,
              alignment: Alignment.centerLeft,
            ),
          ),

          AppSpacing.w8,

          // %
          Expanded(
            flex: 1,
            child: Text('${percentage.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelLarge),
          ),

          AppSpacing.w8,

          // Tiền (chiếm nhiều nhất)
          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: PriceText(
                amount: value.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    FamilyTopCategoryItemModel category,
  ) {
    final categoryName = category.categoryName ?? 'Khác';
    final iconPath = CategoryIconHelper.getIconPath(categoryName, 'expense');
    final percentage = category.percentage ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.md,
        color: TColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: AppPadding.a8,
      child: Row(
        children: [
          Image.asset(
            iconPath,
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1),
                  borderRadius: AppBorderRadius.sm,
                ),
                child: const Icon(
                  Iconsax.more,
                  color: TColors.primary,
                ),
              );
            },
          ),
          AppSpacing.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OverflowMarqueeText(
                  text: categoryName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  alignment: Alignment.centerLeft,
                ),
                AppSpacing.h4,
                Row(
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: TColors.darkerGrey,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.w8,
          PriceText(amount: (category.total ?? 0).toString()),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: TColors.black,
          ),
    );
  }
}
