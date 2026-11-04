import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  final String iconCode;
  final int colorValue;
  final double size;
  final double padding;

  const CategoryIcon({
    super.key,
    required this.iconCode,
    required this.colorValue,
    this.size = 20,
    this.padding = 10,
  });

  static IconData getIcon(String code) {
    switch (code) {
      // Income
      case 'work':
        return Icons.work_outline;
      case 'laptop_mac':
        return Icons.laptop_mac;
      case 'storefront':
        return Icons.storefront;
      case 'real_estate_agent':
        return Icons.real_estate_agent;
      case 'trending_up':
        return Icons.trending_up;
      case 'military_tech':
        return Icons.military_tech;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'assignment_return':
        return Icons.assignment_return;
      case 'monetization_on':
        return Icons.monetization_on_outlined;

      // Expense
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'router':
        return Icons.router_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'medical_services':
        return Icons.medical_services_outlined;
      case 'sports_esports':
        return Icons.sports_esports_outlined;
      case 'face':
        return Icons.face;
      case 'account_balance':
        return Icons.account_balance;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'category':
        return Icons.category_outlined;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        getIcon(iconCode),
        color: color,
        size: size,
      ),
    );
  }
}
