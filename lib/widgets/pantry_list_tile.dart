import 'package:flutter/material.dart';

import '../models/pantry_item.dart';

class PantryListTile extends StatelessWidget {
  const PantryListTile({super.key, required this.item});

  final PantryItem item;

  String _formatDate(DateTime d) {
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text(
        '${item.category} • Qty: ${item.quantity} • Expires: ${_formatDate(item.expiryDate)}',
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
