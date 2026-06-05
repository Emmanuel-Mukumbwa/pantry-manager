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

    List<Widget> sections = [];

    if (expired.isNotEmpty) {
      sections.add(const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('Expired',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red)),
      ));
      for (final item in expired) {
        sections.add(_ExpiryTile(item: item, isExpired: true));
      }
      sections.add(const SizedBox(height: 16));
    }

    if (expiring.isNotEmpty) {
      sections.add(const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('Expiring within 7 days',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange)),
      ));
      for (final item in expiring) {
        sections.add(_ExpiryTile(item: item, isExpired: false));
      }
      sections.add(const SizedBox(height: 16));
    }

    if (pantry.lowStockItems.isNotEmpty) {
      sections.add(const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('Low stock',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
      ));
      for (final item in pantry.lowStockItems) {
        sections.add(_LowStockTile(item: item));
      }
    }

    if (sections.isEmpty) {
      sections.add(const Center(child: Text('No urgent items!')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiry & Low Stock'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: sections,
      ),
    );
  }
}

class _ExpiryTile extends StatelessWidget {
  const _ExpiryTile({
    required this.item,
    required this.isExpired,
  });

  final PantryItem item;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isExpired ? Icons.warning : Icons.event_busy,
          color: isExpired ? Colors.red : Colors.orange,
        ),
        title: Text(item.name, style: const TextStyle(color: Colors.black87)),
        subtitle: Text(
            'Expires: ${item.expiryDate.toLocal().toString().split(' ').first}',
            style: const TextStyle(color: Colors.black54)),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            await context
                .read<PantryProvider>()
                .discardItem(item.id, source: 'expiry_screen');
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ItemDetailScreen(itemId: item.id)),
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
        title: Text(item.name, style: const TextStyle(color: Colors.black87)),
        subtitle: Text(
            '${item.quantity} ${item.unit} (threshold ${item.threshold})',
            style: const TextStyle(color: Colors.black54)),
        trailing: IconButton(
          icon: const Icon(Icons.shopping_cart, color: Colors.teal),
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
            MaterialPageRoute(
                builder: (_) => ItemDetailScreen(itemId: item.id)),
          );
        },
      ),
    );
  }
}