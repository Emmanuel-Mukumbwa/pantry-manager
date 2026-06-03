import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/pantry_provider.dart';
import '../providers/shopping_provider.dart';
import '../models/pantry_item.dart';
import '../models/shopping_item.dart';
import 'item_detail_screen.dart';

class ExpiryTrackerScreen extends StatelessWidget {
  const ExpiryTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryProvider>();
    final expiring = pantry.getItemsExpiringWithin(7);
    final expired = pantry.expiredItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Expiry & Low Stock')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (expired.isNotEmpty) ...[
            const Text('Expired', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            ...expired.map((e) => _ExpiryTile(item: e, isExpired: true)),
            const SizedBox(height: 16),
          ],
          if (expiring.isNotEmpty) ...[
            const Text('Expiring within 7 days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 8),
            ...expiring.map((e) => _ExpiryTile(item: e, isExpired: false)),
            const SizedBox(height: 16),
          ],
          if (pantry.lowStockItems.isNotEmpty) ...[
            const Text('Low stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...pantry.lowStockItems.map((e) => _LowStockTile(item: e)),
          ],
          if (expired.isEmpty && expiring.isEmpty && pantry.lowStockItems.isEmpty)
            const Center(child: Text('No urgent items!')),
        ],
      ),
    );
  }
}

class _ExpiryTile extends StatelessWidget {
  const _ExpiryTile({required this.item, required this.isExpired});

  final PantryItem item;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(isExpired ? Icons.warning : Icons.event_busy, color: isExpired ? Colors.red : Colors.orange),
        title: Text(item.name),
        subtitle: Text('Expires: ${item.expiryDate.toLocal().toString().split(' ').first}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            await context.read<PantryProvider>().discardItem(item.id, source: 'expiry_screen');
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
          );
        },
      ),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({required this.item});

  final PantryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.warning_amber, color: Colors.orange),
        title: Text(item.name),
        subtitle: Text('${item.quantity} ${item.unit} (threshold ${item.threshold})'),
        trailing: IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () async {
            final shoppingProvider = context.read<ShoppingProvider>();
            await shoppingProvider.addToShoppingList(
              ShoppingItem(
                id: const Uuid().v4(),
                name: item.name,
                quantity: item.threshold.toDouble(),
                unit: item.unit,
                isPurchased: false,
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to shopping list')),
            );
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
          );
        },
      ),
    );
  }
}