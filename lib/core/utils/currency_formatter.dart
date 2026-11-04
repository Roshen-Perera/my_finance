import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static final NumberFormat _numberFormat = NumberFormat('#,##0.00');

  /// Convert minor units (cents) to formatted currency string (e.g., "Rs. 15,250.00")
  static String formatCents(
    int cents, {
    String symbol = AppConstants.defaultCurrencySymbol,
    bool showSign = false,
    bool isExpense = false,
  }) {
    final double value = cents / AppConstants.centsFactor;
    final String formattedNumber = _numberFormat.format(value.abs());
    
    final String sign;
    if (showSign) {
      if (cents < 0 || isExpense) {
        sign = '- ';
      } else if (cents > 0) {
        sign = '+ ';
      } else {
        sign = '';
      }
    } else if (cents < 0) {
      sign = '- ';
    } else {
      sign = '';
    }

    final String cleanSymbol = symbol.trim().isEmpty ? '' : '$symbol ';
    return '$sign$cleanSymbol$formattedNumber';
  }

  /// Convert minor units (cents) to a double amount (e.g. 15050 -> 150.50)
  static double centsToDouble(int cents) {
    return cents / AppConstants.centsFactor;
  }

  /// Convert a double or string input to integer minor units (cents)
  static int doubleToCents(double amount) {
    return (amount * AppConstants.centsFactor).round();
  }

  /// Parse user input string e.g., "1,500.50" or "1500" into integer cents
  static int? parseToCents(String text) {
    final String clean = text.replaceAll(',', '').replaceAll(' ', '').trim();
    if (clean.isEmpty) return null;
    final double? parsed = double.tryParse(clean);
    if (parsed == null) return null;
    return (parsed * AppConstants.centsFactor).round();
  }

  /// Format as compact currency e.g., "Rs. 1.2M" or "Rs. 450K"
  static String formatCompactCents(int cents, {String symbol = 'Rs.'}) {
    final double value = cents / AppConstants.centsFactor;
    final absVal = value.abs();
    final sign = cents < 0 ? '-' : '';

    if (absVal >= 10000000) {
      return '$sign$symbol ${(absVal / 10000000).toStringAsFixed(2)} Cr';
    } else if (absVal >= 1000000) {
      return '$sign$symbol ${(absVal / 1000000).toStringAsFixed(1)} M';
    } else if (absVal >= 1000) {
      return '$sign$symbol ${(absVal / 1000).toStringAsFixed(1)} k';
    } else {
      return formatCents(cents, symbol: symbol);
    }
  }
}
