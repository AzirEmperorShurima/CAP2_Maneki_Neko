import 'package:intl/intl.dart';

class TFormatter {
  /// Default date header formatter in Vietnamese
  static String formatDateHeader(DateTime date) {
    final vietnameseDays = [
      'Chủ nhật',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7'
    ];
    final dayOfWeek = vietnameseDays[date.weekday % 7];
    final formattedDate = DateFormat('dd/MM').format(date);
    return '$dayOfWeek, $formattedDate';
  }

  static String formatDateMonth(DateTime? date) {
    date ??= DateTime.now();
    return DateFormat('dd/MM').format(date);
  }

  static String formatDateTimeFull(DateTime? date) {
    date ??= DateTime.now();
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(date);
  }

  static String formatDate(DateTime? date) {
    date ??= DateTime.now();
    return DateFormat('dd-MMM-yyyy')
        .format(date); // Customize the date format as needed
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\$')
        .format(amount); // Customize the currency locale and symbol as needed
  }

  /// Format số theo định dạng Việt Nam (dấu chấm làm phân cách hàng nghìn)
  /// Ví dụ: 1000 -> 1.000, 1000000 -> 1.000.000, 100 -> 100
  static String formatVietnameseNumber(String amount) {
    // Loại bỏ tất cả ký tự không phải số và dấu chấm/phẩy
    String cleanAmount = amount.replaceAll(RegExp(r'[^\d.,]'), '');

    // Tách phần nguyên và phần thập phân (nếu có)
    String integerPart = cleanAmount;
    String decimalPart = '';

    if (cleanAmount.contains('.') || cleanAmount.contains(',')) {
      // Lấy phần thập phân cuối cùng (có thể là dấu chấm hoặc phẩy)
      int lastDotIndex = cleanAmount.lastIndexOf('.');
      int lastCommaIndex = cleanAmount.lastIndexOf(',');
      int separatorIndex =
          lastDotIndex > lastCommaIndex ? lastDotIndex : lastCommaIndex;

      if (separatorIndex != -1) {
        integerPart = cleanAmount.substring(0, separatorIndex);
        decimalPart = cleanAmount.substring(separatorIndex + 1);
      }
    }

    // Loại bỏ tất cả dấu chấm/phẩy trong phần nguyên để parse số
    integerPart = integerPart.replaceAll(RegExp(r'[^\d]'), '');

    // Nếu phần nguyên rỗng, trả về nguyên bản
    if (integerPart.isEmpty) {
      return amount;
    }

    // Parse thành số
    try {
      int number = int.parse(integerPart);

      // Format phần nguyên với dấu chấm làm phân cách hàng nghìn
      String numberStr = number.toString();
      String formattedInteger = '';

      // Đảo ngược chuỗi và thêm dấu chấm mỗi 3 chữ số
      String reversed = numberStr.split('').reversed.join();
      for (int i = 0; i < reversed.length; i++) {
        if (i > 0 && i % 3 == 0) {
          formattedInteger = '.$formattedInteger';
        }
        formattedInteger = reversed[i] + formattedInteger;
      }

      // Nếu có phần thập phân và không phải là "0", thêm vào với dấu phẩy
      if (decimalPart.isNotEmpty && decimalPart != '0') {
        // Loại bỏ các số 0 ở cuối phần thập phân
        String trimmedDecimal = decimalPart.replaceAll(RegExp(r'0+$'), '');
        if (trimmedDecimal.isNotEmpty) {
          return '$formattedInteger,$trimmedDecimal';
        }
      }

      return formattedInteger;
    } catch (e) {
      // Nếu không parse được, trả về nguyên bản
      return amount;
    }
  }

  static String formatPhoneNumber(String phoneNumber) {
    // Assuming a 10-digit US phone number format: (123) 456-7890
    if (phoneNumber.length == 10) {
      return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6)}';
    } else if (phoneNumber.length == 11) {
      return '(${phoneNumber.substring(0, 4)}) ${phoneNumber.substring(4, 7)} ${phoneNumber.substring(7)}';
    }
    // Add more custom phone number formatting logic for different formats if needed.
    return phoneNumber;
  }

  // Not fully tested.
  static String internationalFormatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters from the phone number
    var digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Extract the country code from the digitsOnly
    String countryCode = '+${digitsOnly.substring(0, 2)}';
    digitsOnly = digitsOnly.substring(2);

    // Add the remaining digits with proper formatting
    final formattedNumber = StringBuffer();
    formattedNumber.write('($countryCode) ');

    int i = 0;
    while (i < digitsOnly.length) {
      int groupLength = 2;
      if (i == 0 && countryCode == '+1') {
        groupLength = 3;
      }

      int end = i + groupLength;
      formattedNumber.write(digitsOnly.substring(i, end));

      if (end < digitsOnly.length) {
        formattedNumber.write(' ');
      }
      i = end;
    }

    return formattedNumber.toString();
  }
}

/*
*
*
* */
