/// Helper class để map category name sang icon path
class CategoryIconHelper {
  /// Map category name (expense) sang icon path
  static const Map<String, String> _expenseIconMap = {
    'Ăn uống': 'assets/images/icons/food.png',
    'Chi tiêu hằng ngày': 'assets/images/icons/daily.png',
    'Di chuyển': 'assets/images/icons/traffic.png',
    'Xã Giao': 'assets/images/icons/beer.png',
    'Nhà ở': 'assets/images/icons/house.png',
    'Quà tặng': 'assets/images/icons/box.png',
    'Điện thoại/Internet': 'assets/images/icons/phone.png',
    'Quần áo/Mua sắm': 'assets/images/icons/clothes.png',
    'Giải trí': 'assets/images/icons/entertaiment.png',
    'Làm đẹp': 'assets/images/icons/cosmetics.png',
    'Y tế/Sức khỏe': 'assets/images/icons/health.png',
    'Thuế/Phạt': 'assets/images/icons/tax.png',
    // Fallback
    'Chi tiêu Khác': 'assets/images/icons/money.png',
    'Chuyển khoản': 'assets/images/icons/money_transfer.png',
  };

  /// Map category name (income) sang icon path
  static const Map<String, String> _incomeIconMap = {
    'Lương': 'assets/images/icons/salary.png',
    'Quà tặng': 'assets/images/icons/money.png',
    'Chuyển khoản': 'assets/images/icons/money.png',
    'Thu nhập Khác': 'assets/images/icons/money.png',
    // Có thể thêm sau nếu có thêm categories
    'Bonus': 'assets/images/icons/money.png',
    'Investment': 'assets/images/icons/investment.png',
    'Part time': 'assets/images/icons/part-time.png',
    'Freelance': 'assets/images/icons/freelancer.png',
  };

  /// Default icon path khi không tìm thấy
  static const String defaultIcon = 'assets/images/icons/money.png';

  /// Lấy icon path dựa trên category name và type
  ///
  /// [categoryName] - Tên của category
  /// [type] - Loại transaction ('expense' hoặc 'income')
  ///
  /// Returns icon path, nếu không tìm thấy thì trả về defaultIcon
  static String getIconPath(String? categoryName, String? type) {
    if (categoryName == null || categoryName.isEmpty) {
      return defaultIcon;
    }

    final normalizedName = categoryName.trim();

    if (type == 'expense') {
      return _expenseIconMap[normalizedName] ?? defaultIcon;
    } else if (type == 'income') {
      return _incomeIconMap[normalizedName] ?? defaultIcon;
    }

    return defaultIcon;
  }
}

