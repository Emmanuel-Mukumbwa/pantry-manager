import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_item.dart';
import '../providers/pantry_provider.dart';
import '../providers/shopping_provider.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedUnit = 'piece';

  // Base units (same as add/edit screen)
  final List<String> _baseUnits = const [
    'kg', 'g', 'litre', 'ml', 'piece', 'dozen', 'pack', 'can', 'bottle',
    'box', 'bunch', 'slice', 'cup', 'tablespoon', 'teaspoon',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _buildUnitMenuItems() {
    final pantryProvider = Provider.of<PantryProvider>(context, listen: false);
    final customUnits = pantryProvider.customUnits;
    final allUnits = <String>[..._baseUnits];
    for (final cu in customUnits) {
      if (!allUnits.contains(cu)) allUnits.add(cu);
    }
    allUnits.sort();

    final items = allUnits.map((unit) {
      return DropdownMenuItem<String>(
        value: unit,
        child: Text(unit),
      );
    }).toList();

    items.add(
      const DropdownMenuItem<String>(
        value: '__custom__',
        child: Text('+ Custom...', style: TextStyle(color: Colors.teal)),
      ),
    );
    return items;
  }

  Future<void> _showCustomUnitDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add custom unit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., bunch, pinch, clove',
            labelText: 'Unit name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final unit = controller.text.trim().toLowerCase();
              if (unit.isNotEmpty) {
                Navigator.pop(ctx, unit);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null) {
      final pantryProvider = Provider.of<PantryProvider>(context, listen: false);
      await pantryProvider.addCustomUnit(result);
      setState(() {
        _selectedUnit = result;
      });
    }
  }

  void _showAddDialog() {
    _nameController.clear();
    _quantityController.clear();
    _selectedUnit = 'piece';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Shopping Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                items: _buildUnitMenuItems(),
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) async {
                  if (value == '__custom__') {
                    await _showCustomUnitDialog();
                  } else if (value != null) {
                    setState(() => _selectedUnit = value);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              final qty = double.tryParse(_quantityController.text.trim()) ?? 1.0;
              await context.read<ShoppingProvider>().addToShoppingList(
                ShoppingItem(
                  id: const Uuid().v4(),
                  name: name,
                  quantity: qty,
                  unit: _selectedUnit,
                  isPurchased: false,
                ),
              );
              if (mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generate from low stock',
            onPressed: () async {
              await context.read<ShoppingProvider>().generateShoppingListFromLowStock(
                pantryProvider: context.read<PantryProvider>(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ShoppingProvider>(
          builder: (context, shoppingProvider, _) {
            final pending = shoppingProvider.shoppingList
                .where((e) => !e.isPurchased)
                .toList(growable: false);
            final purchased = shoppingProvider.shoppingList
                .where((e) => e.isPurchased)
                .toList(growable: false);

            if (shoppingProvider.shoppingList.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No shopping items yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add one or generate from low-stock items.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pending.isNotEmpty) ...[
                  _SectionHeader(title: 'Pending (${pending.length})'),
                  const SizedBox(height: 10),
                  ..._buildShoppingItems(context, pending),
                ],
                if (purchased.isNotEmpty) ...[
                  if (pending.isNotEmpty) const SizedBox(height: 16),
                  _SectionHeader(title: 'Purchased (${purchased.length})'),
                  const SizedBox(height: 10),
                  ..._buildShoppingItems(context, purchased),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildShoppingItems(BuildContext context, List<ShoppingItem> items) {
    return items.map((item) {
      return Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) async {
                await context.read<ShoppingProvider>().removeFromShoppingList(item.id);
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
            if (!item.isPurchased)
              SlidableAction(
                onPressed: (_) async {
                  await context.read<ShoppingProvider>().moveToPantry(
                    shoppingId: item.id,
                    pantryProvider: context.read<PantryProvider>(),
                  );
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.add_shopping_cart,
                label: 'Add to pantry',
              ),
          ],
        ),
        child: Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Checkbox(
              value: item.isPurchased,
              onChanged: (_) async {
                await context.read<ShoppingProvider>().togglePurchased(item.id);
              },
            ),
            title: Text(
              item.name,
              style: TextStyle(
                decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                color: item.isPurchased ? Colors.grey.shade600 : Colors.black87,
              ),
            ),
            subtitle: Text(
              '${item.quantity} ${item.unit}',
              style: TextStyle(
                color: item.isPurchased ? Colors.grey.shade500 : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      );
    }).toList(growable: false);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }
}