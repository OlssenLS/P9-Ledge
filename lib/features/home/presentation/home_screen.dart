import 'package:flutter/material.dart';
import '../../transactions/presentation/transactions_screen.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../accounts/presentation/accounts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TransactionsScreen(),
    AccountsScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Accounts'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
        ],
      ),
    );
  }
}
