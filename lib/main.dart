import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/meal_planner_provider.dart';
import 'providers/pantry_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/shopping_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/expense_provider.dart';
import 'screens/home_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'screens/recipes_list_screen.dart';
import 'screens/meal_planner_screen.dart';
import 'screens/expiry_tracker_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PantryProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => MealPlannerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          const teal = Color(0xFF0A6375);
          const orange = Color(0xFFF28C38);
          final lightTheme = ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: const ColorScheme.light(
              primary: teal,
              secondary: orange,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: teal,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black26),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: teal, width: 1.5),
              ),
              labelStyle: const TextStyle(color: Colors.black54),
              hintStyle: const TextStyle(color: Colors.black38),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black87, fontSize: 14),
              bodyMedium: TextStyle(color: Colors.black87, fontSize: 12),
              titleLarge: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
              titleMedium: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              labelLarge: TextStyle(color: Colors.black87),
            ),
          );
          final darkTheme = ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: teal,
              secondary: orange,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: teal,
              elevation: 0,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: teal, width: 1.5),
              ),
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: const TextStyle(color: Colors.white38),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white, fontSize: 14),
              bodyMedium: TextStyle(color: Colors.white70, fontSize: 12),
              titleLarge: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
              titleMedium: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              labelLarge: TextStyle(color: Colors.white),
            ),
          );
          return MaterialApp(
            title: 'Pantry Manager V5',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeNotifier.mode,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => FutureBuilder<bool>(
                    future: WelcomeScreen.needsToShow(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.data == true) {
                        return const WelcomeScreen();
                      }
                      return const MainNavigation();
                    },
                  ),
              '/home': (context) => const MainNavigation(),
            },
          );
        },
      ),
    );
  }
}

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const ShoppingListScreen(),
      const RecipesListScreen(),
      const MealPlannerScreen(),
      SettingsScreen(
        onReset: _handleReset,
        onReplayTutorial: _handleReplayTutorial,
      ),
    ];
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Future<void> _handleReset() async {
    // Clear all providers
    try {
      await context.read<PantryProvider>().clearAll();
      await context.read<ShoppingProvider>().clearAll();
      await context.read<RecipeProvider>().clearAll();
      await context.read<MealPlannerProvider>().clearAll();
      await context.read<ExpenseProvider>().clearAll();
      await context.read<CurrencyProvider>().resetToDefault();
    } catch (_) {}
    if (mounted) {
      context.read<ThemeNotifier>().setMode(ThemeMode.system);
    }
    await WelcomeScreen.resetFlag();
    if (!mounted) return;
    // Navigate to the initial route – rebuilds everything and shows welcome
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _handleReplayTutorial() async {
    await WelcomeScreen.resetFlag();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0A6375)),
              child: Text(
                'Pantry Manager',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Shopping List'),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Recipes'),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Meal Planner'),
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Expiry Tracker'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ExpiryTrackerScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Currency'),
              onTap: () {
                final currencyProvider =
                    Provider.of<CurrencyProvider>(context, listen: false);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Select Currency'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: currencyProvider.availableCurrencies.length,
                        itemBuilder: (context, index) {
                          final code =
                              currencyProvider.availableCurrencies[index];
                          final symbol = CurrencyProvider.getSymbol(code);
                          return ListTile(
                            title: Text('$code ($symbol)'),
                            onTap: () {
                              currencyProvider.setCurrency(code);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Theme'),
              onTap: () {
                final themeNotifier =
                    Provider.of<ThemeNotifier>(context, listen: false);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Theme Mode'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('Light'),
                          onTap: () {
                            themeNotifier.setMode(ThemeMode.light);
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('Dark'),
                          onTap: () {
                            themeNotifier.setMode(ThemeMode.dark);
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('System'),
                          onTap: () {
                            themeNotifier.setMode(ThemeMode.system);
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                _onItemTapped(4);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Shopping'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu), label: 'Recipes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Meal Plan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}