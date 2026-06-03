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
import 'screens/expiry_tracker_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF0A6375);
    const orange = Color(0xFFF28C38);

    final lightColorScheme = const ColorScheme.light(
      primary: teal,
      secondary: orange,
      surface: Colors.white,
      background: Color(0xFFF5F5F5),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: lightColorScheme,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.black12),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        elevation: 2,
        shadowColor: Colors.black12,
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 14),
        bodyMedium: TextStyle(color: Colors.black87, fontSize: 12),
        titleLarge: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
        labelLarge: TextStyle(color: Colors.black87),
      ),
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
          final effectiveTheme = baseTheme.copyWith(
            brightness: themeProvider.mode == ThemeMode.light
                ? Brightness.light
                : themeProvider.mode == ThemeMode.dark
                ? Brightness.dark
                : WidgetsBinding.instance.platformDispatcher.platformBrightness,
          );
          return MaterialApp(
            title: 'Pantry Manager V5',
            theme: effectiveTheme,
            themeMode: themeProvider.mode,
            debugShowCheckedModeBanner: false,
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0A6375)),
              child: Text(
                'Pantry Manager',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpiryTrackerScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Theme'),
              onTap: () {
                final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
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
                            themeProvider.setMode(ThemeMode.light);
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('Dark'),
                          onTap: () {
                            themeProvider.setMode(ThemeMode.dark);
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('System'),
                          onTap: () {
                            themeProvider.setMode(ThemeMode.system);
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                );
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
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shopping'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Meal Plan'),
        ],
      ),
    );
  }
}