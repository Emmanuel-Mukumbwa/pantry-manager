import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/pantry_provider.dart';
import '../providers/shopping_provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/insight_card.dart';
import 'add_edit_screen.dart';
import 'shopping_list_screen.dart';
import 'recipes_list_screen.dart';
import 'meal_planner_screen.dart';
import 'expiry_tracker_screen.dart';
import 'pantry_items_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pantryProvider = Provider.of<PantryProvider>(context);
    final shoppingProvider = Provider.of<ShoppingProvider>(context);
    final recipeProvider = Provider.of<RecipeProvider>(context);

    final totalItems = pantryProvider.items.length;
    final lowStockCount = pantryProvider.lowStockItems.length;
    final expiringSoonCount = pantryProvider.getItemsExpiringWithin(7).length;
    final shoppingCount = shoppingProvider.unpurchasedCount;
    final recipeCount = recipeProvider.recipes.length;

    final greeting = _getGreeting();
    final urgentCount = lowStockCount + expiringSoonCount;

    // Build category breakdown (category name -> number of items)
    final categoryCount = <String, int>{};
    for (final item in pantryProvider.items) {
      categoryCount[item.category] = (categoryCount[item.category] ?? 0) + 1;
    }

    final now = DateTime.now();
    final time24 = DateFormat('HH:mm').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantry Manager', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          badges.Badge(
            showBadge: urgentCount > 0,
            badgeContent: Text('$urgentCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
            badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.black87),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpiryTrackerScreen()));
              },
              tooltip: 'Urgent items',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.list, color: Colors.black87),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PantryItemsListScreen()));
            },
            tooltip: 'All pantry items',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => pantryProvider.loadItems(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, Chef!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Today is ${DateFormat('EEEE, MMMM d').format(now)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const Spacer(),
                  Text(
                    time24,
                    style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: [
                  _CompactSummaryCard(icon: Icons.inventory_2_outlined, label: 'Total items', value: '$totalItems'),
                  _CompactSummaryCard(icon: Icons.warning_amber_rounded, label: 'Low stock', value: '$lowStockCount', accentColor: Colors.orange),
                  _CompactSummaryCard(icon: Icons.event_available, label: 'Expiring ≤7d', value: '$expiringSoonCount', accentColor: Colors.redAccent),
                  _CompactSummaryCard(icon: Icons.shopping_cart_outlined, label: 'Shopping list', value: '$shoppingCount', accentColor: Colors.teal),
                  _CompactSummaryCard(icon: Icons.restaurant_menu, label: 'Recipes', value: '$recipeCount'),
                ],
              ),
              const SizedBox(height: 24),

              // Category breakdown
              if (categoryCount.isNotEmpty) ...[
                const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categoryCount.entries.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final entry = categoryCount.entries.elementAt(index);
                      return Chip(
                        label: Text('${entry.key} (${entry.value})'),
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: const TextStyle(color: Colors.black87),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Insights
              const Text('Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InsightCard(title: 'Most stocked', value: pantryProvider.mostStockedCategory, icon: Icons.storage),
                  InsightCard(title: 'Most used', value: pantryProvider.mostUsedCategory, icon: Icons.trending_up),
                  InsightCard(
                    title: 'Recent additions',
                    value: pantryProvider.recentlyAdded.isEmpty ? 'None' : pantryProvider.recentlyAdded.first.name,
                    icon: Icons.add_circle_outline,
                  ),
                  InsightCard(
                    title: 'Last consumed',
                    value: pantryProvider.recentConsumption.isEmpty ? 'None' : DateFormat('MMM d').format(pantryProvider.recentConsumption.first.dateTime),
                    icon: Icons.history,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick actions
              const Text('Quick actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditScreen(item: null))),
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: const Text('Add item', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A6375), padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
                      icon: const Icon(Icons.shopping_cart, size: 18, color: Colors.black87),
                      label: const Text('Shopping', style: TextStyle(color: Colors.black87)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black38), padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipesListScreen())),
                      icon: const Icon(Icons.restaurant_menu, size: 18, color: Colors.black87),
                      label: const Text('Recipes', style: TextStyle(color: Colors.black87)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black38), padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPlannerScreen())),
                      icon: const Icon(Icons.calendar_month, size: 18, color: Colors.black87),
                      label: const Text('Meal plan', style: TextStyle(color: Colors.black87)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black38), padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpiryTrackerScreen())),
                      icon: const Icon(Icons.warning, size: 18, color: Colors.black87),
                      label: const Text('Expiry', style: TextStyle(color: Colors.black87)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black38), padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantryItemsListScreen())),
                      icon: const Icon(Icons.list, size: 18, color: Colors.black87),
                      label: const Text('All items', style: TextStyle(color: Colors.black87)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black38), padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Urgent items banner
              if (urgentCount > 0)
                Card(
                  color: Colors.orange.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: const Text('Urgent items', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                    subtitle: Text('$lowStockCount low stock, $expiringSoonCount expiring soon', style: const TextStyle(color: Colors.black54)),
                    trailing: const Icon(Icons.arrow_forward, color: Colors.black54),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpiryTrackerScreen())),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditScreen(item: null))),
        backgroundColor: const Color(0xFF0A6375),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _CompactSummaryCard extends StatelessWidget {
  const _CompactSummaryCard({required this.icon, required this.label, required this.value, this.accentColor});
  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? const Color(0xFF0A6375);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}