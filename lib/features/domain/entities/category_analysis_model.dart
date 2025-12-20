class CategoryAnalysisModel {
  final String? type;
  final List<CategoryAnalysisItem>? categories;
  final double? grandTotal;

  CategoryAnalysisModel({
    this.type,
    this.categories,
    this.grandTotal,
  });
}

class CategoryAnalysisItem {
  final String? categoryId;
  final String? categoryName;
  final double? total;
  final int? count;
  final double? avgAmount;
  final String? percentage;

  CategoryAnalysisItem({
    this.categoryId,
    this.categoryName,
    this.total,
    this.count,
    this.avgAmount,
    this.percentage,
  });
}
