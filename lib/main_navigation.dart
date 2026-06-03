import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/meal_planner_provider.dart';
import 'providers/pantry_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/shopping_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'screens/recipes_list_screen.dart';
import 'screens/meal_planner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF0A6375);
    const orange = Color(0xFFF28C38);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(secondary: orange, primary: teal),
      scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: teal,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: teal,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withOpacity(0.08))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withOpacity(0.12))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: teal, width: 1.5)),
        labelStyle: TextStyle(color: teal.withOpacity(0.8)),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.black.withOpacity(0.05))),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.06),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: teal),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PantryProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => MealPlannerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Pantry Manager V5',
            theme: baseTheme,
            themeMode: themeProvider.mode,
            home: const MainNavigation(),
          );
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ShoppingListScreen(),
    RecipesListScreen(),
    MealPlannerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shopping'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Meal Plan'),
        ],
      ),
    );
  }
}