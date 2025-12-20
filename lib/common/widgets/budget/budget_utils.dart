/// Utility functions cho budget

String mapBudgetType(String? type) {
  switch (type) {
    case 'daily':
      return 'Hằng ngày';
    case 'monthly':
      return 'Hằng tháng';
    case 'yearly':
      return 'Hằng năm';
    default:
      return type ?? '';
  }
}
