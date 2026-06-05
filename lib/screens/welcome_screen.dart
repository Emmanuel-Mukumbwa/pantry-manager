import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  static const String _key = 'welcome_shown_v1';

  static Future<bool> needsToShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key) ?? false);
  }

  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<void> resetFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;   // now 5 slides

  void _goToHome() {
    WelcomeScreen.markShown();
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToHome,
                child: const Text('Skip'),
              ),
            ),
            // Slides
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: const [
                  _Slide(
                    title: 'Welcome to Pantry Manager',
                    description:
                        'Keep track of your pantry, save money, and never run out of ingredients.',
                    icon: Icons.kitchen,
                  ),
                  _Slide(
                    title: 'Manage Inventory',
                    description:
                        'Add items with quantity, expiry date, and even price per unit. Get low‑stock alerts.',
                    icon: Icons.inventory,
                  ),
                  _Slide(
                    title: 'Track Expenses',
                    description:
                        'Record what you spend on groceries. View total spent, monthly breakdowns, and consumption value.',
                    icon: Icons.attach_money,
                  ),
                  _Slide(
                    title: 'Plan Meals & Cook',
                    description:
                        'Create recipes, plan your week, and let the app deduct ingredients automatically when you cook.',
                    icon: Icons.calendar_month,
                  ),
                  _Slide(
                    title: 'Smart Shopping & Currency',
                    description:
                        'Generate shopping suggestions from low stock. Change currency from the drawer – prices update everywhere.',
                    icon: Icons.shopping_cart,
                  ),
                ],
              ),
            ),
            // Page indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF0A6375)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // Action button
            if (_currentPage == _totalPages - 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: ElevatedButton(
                  onPressed: _goToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A6375),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Get Started'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: ElevatedButton(
                  onPressed: () => _controller.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A6375),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Next'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  const _Slide({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: const Color(0xFF0A6375)),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}