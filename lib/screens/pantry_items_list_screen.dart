import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry_provider.dart';
import '../providers/currency_provider.dart'; // new
import '../models/pantry_item.dart';
import 'add_edit_screen.dart';
import 'item_detail_screen.dart';

class PantryItemsListScreen extends StatefulWidget {
  const PantryItemsListScreen({super.key});

  @override
  State<PantryItemsListScreen> createState() => _PantryItemsListScreenState();
}

class _PantryItemsListScreenState extends State<PantryItemsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<String> get categories {
    final pantry = context.read<PantryProvider>();
    final cats = <String>{'All'};
    for (final item in pantry.items) {
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

  Future<void> _confirmDelete(BuildContext context, PantryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Delete "${item.name}" from your pantry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<PantryProvider>().deleteItem(item.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantryProvider = context.watch<PantryProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final items = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Pantry Items'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
          if (categories.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: const Color(0xFF0A6375),
                        labelStyle: TextStyle(color: _selectedCategory == cat ? Colors.white : Colors.black87),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No items found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final priceString = item.pricePerUnit != null
                          ? ' • ${currencyProvider.currencySymbol}${item.pricePerUnit!.toStringAsFixed(2)}/${item.unit}'
                          : '';
                      final totalValueString = item.pricePerUnit != null
                          ? '${currencyProvider.currencySymbol}${item.totalValue.toStringAsFixed(2)}'
                          : '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.inventory),
                          title: Text(item.name, style: const TextStyle(color: Colors.black87)),
                          subtitle: Text(
                            '${item.quantity} ${item.unit} • ${item.category}$priceString',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (totalValueString.isNotEmpty)
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        totalValueString,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditScreen(item: item)));
                                    } else if (value == 'delete') {
                                      await _confirmDelete(context, item);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditScreen(item: null))),
        backgroundColor: const Color(0xFF0A6375),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
} 