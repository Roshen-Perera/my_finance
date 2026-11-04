class DefaultCategoryItem {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String iconCode;
  final int colorValue;
  final List<String> subcategories;

  const DefaultCategoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCode,
    required this.colorValue,
    this.subcategories = const [],
  });
}

class DefaultCategories {
  static const List<DefaultCategoryItem> incomeCategories = [
    DefaultCategoryItem(
      id: 'inc_salary',
      name: 'Salary',
      type: 'income',
      iconCode: 'work',
      colorValue: 0xFF10B981, // Emerald green
    ),
    DefaultCategoryItem(
      id: 'inc_freelance',
      name: 'Freelance income',
      type: 'income',
      iconCode: 'laptop_mac',
      colorValue: 0xFF059669,
    ),
    DefaultCategoryItem(
      id: 'inc_business',
      name: 'Business income',
      type: 'income',
      iconCode: 'storefront',
      colorValue: 0xFF047857,
    ),
    DefaultCategoryItem(
      id: 'inc_rental',
      name: 'Rental income',
      type: 'income',
      iconCode: 'real_estate_agent',
      colorValue: 0xFF0D9488,
    ),
    DefaultCategoryItem(
      id: 'inc_interest',
      name: 'Interest',
      type: 'income',
      iconCode: 'trending_up',
      colorValue: 0xFF14B8A6,
    ),
    DefaultCategoryItem(
      id: 'inc_bonuses',
      name: 'Bonuses',
      type: 'income',
      iconCode: 'military_tech',
      colorValue: 0xFF06B6D4,
    ),
    DefaultCategoryItem(
      id: 'inc_gifts',
      name: 'Gifts received',
      type: 'income',
      iconCode: 'card_giftcard',
      colorValue: 0xFF0284C7,
    ),
    DefaultCategoryItem(
      id: 'inc_refunds',
      name: 'Refunds',
      type: 'income',
      iconCode: 'assignment_return',
      colorValue: 0xFF6366F1,
    ),
    DefaultCategoryItem(
      id: 'inc_other',
      name: 'Other income',
      type: 'income',
      iconCode: 'monetization_on',
      colorValue: 0xFF8B5CF6,
    ),
  ];

  static const List<DefaultCategoryItem> expenseCategories = [
    DefaultCategoryItem(
      id: 'exp_food',
      name: 'Food and Dining',
      type: 'expense',
      iconCode: 'restaurant',
      colorValue: 0xFFF97316, // Orange
      subcategories: ['Groceries', 'Restaurants', 'Snacks', 'Beverages'],
    ),
    DefaultCategoryItem(
      id: 'exp_transport',
      name: 'Transportation',
      type: 'expense',
      iconCode: 'directions_car',
      colorValue: 0xFF3B82F6, // Blue
      subcategories: ['Fuel', 'Public transport', 'Taxi', 'Vehicle maintenance', 'Parking'],
    ),
    DefaultCategoryItem(
      id: 'exp_housing',
      name: 'Housing',
      type: 'expense',
      iconCode: 'home',
      colorValue: 0xFFEF4444, // Red
      subcategories: ['Rent', 'Electricity', 'Water', 'Maintenance'],
    ),
    DefaultCategoryItem(
      id: 'exp_utilities',
      name: 'Utilities',
      type: 'expense',
      iconCode: 'router',
      colorValue: 0xFF06B6D4, // Cyan
      subcategories: ['Internet', 'Mobile', 'Subscriptions'],
    ),
    DefaultCategoryItem(
      id: 'exp_shopping',
      name: 'Shopping',
      type: 'expense',
      iconCode: 'shopping_bag',
      colorValue: 0xFFEC4899, // Pink
      subcategories: ['Clothing', 'Electronics', 'Personal items'],
    ),
    DefaultCategoryItem(
      id: 'exp_education',
      name: 'Education',
      type: 'expense',
      iconCode: 'school',
      colorValue: 0xFF8B5CF6, // Purple
      subcategories: ['University', 'Courses', 'Books', 'Other educational expenses'],
    ),
    DefaultCategoryItem(
      id: 'exp_health',
      name: 'Health',
      type: 'expense',
      iconCode: 'medical_services',
      colorValue: 0xFF10B981, // Teal green
      subcategories: ['Medical', 'Pharmacy', 'Healthcare services'],
    ),
    DefaultCategoryItem(
      id: 'exp_entertainment',
      name: 'Entertainment',
      type: 'expense',
      iconCode: 'sports_esports',
      colorValue: 0xFFA855F7, // Purple
      subcategories: ['Movies', 'Gaming', 'Events', 'Outings'],
    ),
    DefaultCategoryItem(
      id: 'exp_personal',
      name: 'Personal',
      type: 'expense',
      iconCode: 'face',
      colorValue: 0xFFEAB308, // Amber
      subcategories: ['Haircuts', 'Personal care', 'Other personal expenses'],
    ),
    DefaultCategoryItem(
      id: 'exp_financial',
      name: 'Financial',
      type: 'expense',
      iconCode: 'account_balance',
      colorValue: 0xFF64748B, // Slate
      subcategories: ['Bank charges', 'Loan interest', 'Financial fees'],
    ),
    DefaultCategoryItem(
      id: 'exp_other',
      name: 'Other',
      type: 'expense',
      iconCode: 'category',
      colorValue: 0xFF94A3B8, // Gray
      subcategories: ['Miscellaneous expenses'],
    ),
  ];
}
