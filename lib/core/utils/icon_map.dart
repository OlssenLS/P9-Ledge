import 'package:flutter/material.dart';

class IconMap {
  static const Map<String, IconData> icons = {
    'home': Icons.home,
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'commute': Icons.commute,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'receipt': Icons.receipt,
    'payments': Icons.payments,
    'account_balance': Icons.account_balance,
    'savings': Icons.savings,
    'sports_esports': Icons.sports_esports,
    'movie': Icons.movie,
    'flight': Icons.flight,
  };

  static IconData getIcon(String name) {
    return icons[name] ?? Icons.category;
  }
}
