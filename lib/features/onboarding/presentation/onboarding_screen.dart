import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Track with Ease',
      'description': 'Manually track your IDR expenses with a beautiful, fast interface.',
      'icon': Icons.account_balance_wallet,
    },
    {
      'title': 'Receipt Scanning',
      'description': '(Coming soon) Snap a picture of your receipt and let AI extract the details instantly.',
      'icon': Icons.receipt_long,
    },
    {
      'title': 'Voice Entry',
      'description': '(Coming soon) Just say "Rp50.000 for coffee" and Ledge handles the rest.',
      'icon': Icons.mic,
    },
    {
      'title': 'Gmail Sync',
      'description': '(Coming soon) Automatically sync transactions from your bank emails.',
      'icon': Icons.mark_email_read,
    },
  ];

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page['icon'],
                          size: 100,
                          color: Theme.of(context).colorScheme.primary, // Turquoise
                        )
                            .animate(target: _currentPage == index ? 1 : 0)
                            .scale(duration: 400.ms, curve: Curves.easeOutBack)
                            .fadeIn(),
                        const SizedBox(height: 40),
                        Text(
                          page['title'],
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        )
                            .animate(target: _currentPage == index ? 1 : 0)
                            .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut)
                            .fadeIn(),
                        const SizedBox(height: 16),
                        Text(
                          page['description'],
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[400],
                              ),
                          textAlign: TextAlign.center,
                        )
                            .animate(target: _currentPage == index ? 1 : 0)
                            .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 100.ms, curve: Curves.easeOut)
                            .fadeIn(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _currentPage == _pages.length - 1
                        ? _completeOnboarding
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
