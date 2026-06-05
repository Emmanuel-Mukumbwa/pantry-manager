import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/pantry_provider.dart';
import '../providers/currency_provider.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key});

  @override 
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final pantryProvider = context.watch<PantryProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();

    final symbol = currencyProvider.currencySymbol;
    final totalSpent = expenseProvider.totalSpent;
    final totalConsumedValue = _calculateTotalConsumedValue(pantryProvider);
    final monthlyPurchases = expenseProvider.monthlyPurchases;
    final categoryPurchases = expenseProvider.categoryPurchases;
    final monthlyConsumption = _calculateMonthlyConsumption(pantryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Total Spent', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '$symbol${totalSpent.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0A6375)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Total Value Consumed', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '$symbol${totalConsumedValue.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Monthly breakdown
          const Text('Monthly Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildMonthlySection(monthlyPurchases, monthlyConsumption, symbol),

          const SizedBox(height: 24),

          // Category breakdown (purchases only)
          const Text('Category Breakdown (Purchases)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...categoryPurchases.entries.map((e) => ListTile(
                title: Text(e.key),
                trailing: Text('$symbol${e.value.toStringAsFixed(2)}'),
              )),
        ],
      ),
    );
  }

  double _calculateTotalConsumedValue(PantryProvider pantryProvider) {
    double total = 0;
    for (final item in pantryProvider.items) {
      if (item.pricePerUnit != null) {
        for (final record in item.consumptionHistory) {
          total += record.amount * item.pricePerUnit!;
        }
      }
    }
    return total;
  }

  Map<String, double> _calculateMonthlyConsumption(PantryProvider pantryProvider) {
    final map = <String, double>{};
    final fmt = DateFormat('yyyy-MM');
    for (final item in pantryProvider.items) {
      if (item.pricePerUnit == null) continue;
      for (final record in item.consumptionHistory) {
        final key = fmt.format(record.dateTime);
        map[key] = (map[key] ?? 0) + record.amount * item.pricePerUnit!;
      }
    }
    return map;
  }

  Widget _buildMonthlySection(
    Map<String, double> purchases,
    Map<String, double> consumption,
    String symbol,
  ) {
    // Combine keys
    final allKeys = {...purchases.keys, ...consumption.keys}.toList()..sort();
    if (allKeys.isEmpty) return const Text('No data yet.');

    return Column(
      children: allKeys.map((key) {
        final p = purchases[key] ?? 0;
        final c = consumption[key] ?? 0;
        return Card(
          child: ExpansionTile(
            title: Text(key),
            subtitle: Text('Purchases: $symbol${p.toStringAsFixed(2)}  |  Consumed: $symbol${c.toStringAsFixed(2)}'),
          ),
        );
      }).toList(),
    );
  }
}