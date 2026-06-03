import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/pantry_provider.dart';
import 'add_edit_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryProvider>();
    final item = pantry.items.firstWhere((i) => i.id == itemId, orElse: () => throw Exception('Item not found'));

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quantity: ${item.quantity} ${item.unit}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Category: ${item.category}'),
                    Text('Threshold: ${item.threshold} ${item.unit}'),
                    Text('Added: ${DateFormat.yMMMd().format(item.addedDate)}'),
                    if (item.lastUsedDate != null) Text('Last used: ${DateFormat.yMMMd().format(item.lastUsedDate!)}'),
                    Text('Expiry: ${DateFormat.yMMMd().format(item.expiryDate)}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final amount = await _showAmountDialog(context, item.quantity);
                              if (amount != null && amount > 0) {
                                await pantry.consumeItem(item.id, amount: amount, source: 'detail_screen');
                              }
                            },
                            icon: const Icon(Icons.remove),
                            label: const Text('Consume'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Discard item?'),
                                  content: const Text('This will remove the entire stock.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await pantry.discardItem(item.id, source: 'detail_screen');
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Discard'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddEditScreen(item: item)),
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete item?'),
                                  content: const Text('This will permanently remove the item.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await pantry.deleteItem(item.id);
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Consumption History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: item.consumptionHistory.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final record = item.consumptionHistory[i];
                return ListTile(
                  title: Text('${record.amount} ${record.unit}'),
                  subtitle: Text('${DateFormat.yMMMd().add_jm().format(record.dateTime)} • ${record.source}'),
                  trailing: Text('Left: ${record.remainingQuantity}'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<double?> _showAmountDialog(BuildContext context, double maxAmount) async {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Consume amount'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Amount (max $maxAmount)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0 && val <= maxAmount) {
                Navigator.pop(ctx, val);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Invalid amount')));
              }
            },
            child: const Text('Consume'),
          ),
        ],
      ),
    );
  }
}