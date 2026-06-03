import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pantry_provider.dart';
import '../providers/shopping_provider.dart';
import '../providers/recipe_provider.dart';
import '../models/pantry_item.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chips.dart';
import '../widgets/insight_card.dart';
import 'add_edit_screen.dart';
import 'shopping_list_screen.dart';
import 'recipes_list_screen.dart';
import 'meal_planner_screen.dart';
import 'expiry_tracker_screen.dart';
import 'item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<String> get categories {
    final cats = <String>{'All'};
    for (final item in context.read<PantryProvider>().items) {
      cats.add(item.category);
    }
    return cats.toList()..sort();
  }

  List<PantryItem> get _filteredItems {
    final pantry = context.read<PantryProvider>();
    var items = pantry.items;
    if (_searchQuery.isNotEmpty) {
      items = items.where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_selectedCategory != 'All') {
      items = items.where((i) => i.category == _selectedCategory).toList();
    }
    return items;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final pantryProvider = context.watch<PantryProvider>();
    final shoppingProvider = context.watch<ShoppingProvider>();
    final recipeProvider = context.watch<RecipeProvider>();

    final totalItems = pantryProvider.items.length;
    final totalQuantity = pantryProvider.items.fold<double>(0.0, (sum, e) => sum + (e.quantity.isNaN ? 0.0 : e.quantity));
    final lowStockCount = pantryProvider.lowStockItems.length;
    final expiringSoonCount = pantryProvider.getItemsExpiringWithin(7).length;
    final shoppingCount = shoppingProvider.unpurchasedCount;
    final recipeCount = recipeProvider.recipes.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantry Manager', style: TextStyle(color: Colors.black87)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black87),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu, color: Colors.black87),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipesListScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.black87),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPlannerScreen())),
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
                '$_greeting, Chef!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Today is ${DateFormat('EEEE, MMMM d').format(DateTime.now())}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),

              SearchBarWidget(controller: _searchController, onChanged: (q) => setState(() => _searchQuery = q)),
              const SizedBox(height: 12),
              FilterChips(categories: categories, selected: _selectedCategory, onSelected: (cat) => setState(() => _selectedCategory = cat)),
              const SizedBox(height: 16),

              // Compact summary cards with border
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: [
                  _CompactSummaryCard(icon: Icons.inventory_2_outlined, label: 'Total items', value: '$totalItems'),
                  _CompactSummaryCard(icon: Icons.scale_outlined, label: 'Total qty', value: totalQuantity.toStringAsFixed(1)),
                  _CompactSummaryCard(icon: Icons.warning_amber_rounded, label: 'Low stock', value: '$lowStockCount', accentColor: Colors.orange),
                  _CompactSummaryCard(icon: Icons.event_available, label: 'Expiring ≤7d', value: '$expiringSoonCount', accentColor: Colors.redAccent),
                  _CompactSummaryCard(icon: Icons.shopping_cart_outlined, label: 'Shopping list', value: '$shoppingCount', accentColor: Colors.teal),
                  _CompactSummaryCard(icon: Icons.restaurant_menu, label: 'Recipes', value: '$recipeCount'),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Insights',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
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

              const Text(
                'Quick actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditScreen(item: null))),
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: const Text('Add item', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A6375),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
                      icon: const Icon(Icons.shopping_cart, size: 18, color: Colors.black87),
                      label: const Text('Shopping', style: TextStyle(color: Colors.black87)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black38),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
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
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black38),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPlannerScreen())),
                      icon: const Icon(Icons.calendar_month, size: 18, color: Colors.black87),
                      label: const Text('Meal plan', style: TextStyle(color: Colors.black87)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black38),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (expiringSoonCount > 0 || lowStockCount > 0)
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
              const SizedBox(height: 16),

              const Text(
                'Pantry items',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredItems.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.black12, height: 8),
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory, color: Colors.black54),
                    title: Text(item.name, style: const TextStyle(color: Colors.black87)),
                    subtitle: Text('${item.quantity} ${item.unit} • ${item.category}', style: const TextStyle(color: Colors.black54)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id))),
                  );
                },
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