import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';

class AddEditScreen extends StatefulWidget {
  const AddEditScreen({super.key, this.item});

  final PantryItem? item;

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();

  // Expanded categories
  final List<String> _categories = const [
    'Grains',
    'Dairy',
    'Vegetables',
    'Fruits',
    'Meat',
    'Spices',
    'Beverages',
    'Canned Goods',
    'Frozen',
    'Snacks',
    'Other',
  ];

  // Base units (common)
  final List<String> _baseUnits = const [
    'kg',
    'g',
    'litre',
    'ml',
    'piece',
    'dozen',
    'pack',
    'can',
    'bottle',
    'box',
    'bunch',
    'slice',
    'cup',
    'tablespoon',
    'teaspoon',
  ];

  // Category-specific default units
  final Map<String, String> _categoryDefaultUnit = {
    'Grains': 'kg',
    'Dairy': 'litre',
    'Vegetables': 'kg',
    'Fruits': 'kg',
    'Meat': 'kg',
    'Spices': 'g',
    'Beverages': 'litre',
    'Canned Goods': 'can',
    'Frozen': 'kg',
    'Snacks': 'pack',
    'Other': 'piece',
  };

  // Keyword-based unit detection (name contains keyword)
  final Map<String, String> _keywordUnit = {
    'egg': 'piece',
    'eggs': 'piece',
    'milk': 'litre',
    'yogurt': 'g',
    'cheese': 'g',
    'butter': 'g',
    'flour': 'kg',
    'rice': 'kg',
    'pasta': 'kg',
    'bread': 'piece',
    'juice': 'litre',
    'soda': 'can',
    'water': 'bottle',
    'oil': 'litre',
    'sugar': 'kg',
    'salt': 'g',
    'pepper': 'g',
    'onion': 'piece',
    'tomato': 'piece',
    'potato': 'kg',
    'carrot': 'piece',
    'apple': 'piece',
    'banana': 'piece',
    'orange': 'piece',
    'chicken': 'kg',
    'beef': 'kg',
    'fish': 'kg',
    'cornflakes': 'box',
  };

  late String _category;
  String _selectedUnit = 'piece';
  int _threshold = 1;
  DateTime _expiryDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      // Editing existing item – preserve original values
      _nameController.text = widget.item!.name;
      _quantityController.text = widget.item!.quantity.toString();
      _category = widget.item!.category;
      _selectedUnit = widget.item!.unit;
      _threshold = widget.item!.threshold;
      _expiryDate = widget.item!.expiryDate;
    } else {
      _category = _categories.first;
      _suggestUnitFromNameAndCategory(); // initial suggestion
    }

    // Listen to name changes for real‑time unit suggestion (only for new items)
    if (widget.item == null) {
      _nameController.addListener(_onNameChanged);
    }
  }

  void _onNameChanged() {
    _suggestUnitFromNameAndCategory();
  }

  void _suggestUnitFromNameAndCategory() {
    final name = _nameController.text.trim().toLowerCase();
    String? suggestedUnit;

    // 1. Try keyword match
    for (final entry in _keywordUnit.entries) {
      if (name.contains(entry.key)) {
        suggestedUnit = entry.value;
        break;
      }
    }

    // 2. Fallback to category default
    if (suggestedUnit == null) {
      suggestedUnit = _categoryDefaultUnit[_category] ?? 'piece';
    }

    if (suggestedUnit != null && suggestedUnit != _selectedUnit) {
      setState(() {
        _selectedUnit = suggestedUnit!;
      });
    }
  }

  @override
  void dispose() {
    if (widget.item == null) {
      _nameController.removeListener(_onNameChanged);
    }
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _expiryDate.isBefore(now) ? now : _expiryDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _expiryDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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

    // Add "Custom..." option
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Item' : 'Add Item')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Please enter a name';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Please enter quantity';
                    final parsed = double.tryParse(value);
                    if (parsed == null) return 'Quantity must be a number';
                    if (parsed <= 0) return 'Quantity must be > 0';
                    return null;
                  },
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
                      setState(() {
                        _selectedUnit = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _threshold.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Low-stock threshold',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final parsed = int.tryParse(v.trim());
                    if (parsed != null) _threshold = parsed;
                  },
                  validator: (v) {
                    final parsed = int.tryParse(v?.trim() ?? '');
                    if (parsed == null) return 'Enter a valid integer';
                    if (parsed < 0) return 'Threshold cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: _categories
                      .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _category = v;
                    });
                    // Re‑suggest unit when category changes (only for new item)
                    if (widget.item == null) {
                      _suggestUnitFromNameAndCategory();
                    }
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Select a category';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(_formatDate(_expiryDate))),
                      TextButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Pick'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    final formState = _formKey.currentState;
                    if (formState == null) return;
                    if (!formState.validate()) return;

                    final name = _nameController.text.trim();
                    final quantity = double.parse(_quantityController.text.trim());
                    final provider = context.read<PantryProvider>();

                    if (widget.item == null) {
                      await provider.addItem(
                        name: name,
                        quantity: quantity,
                        category: _category,
                        expiryDate: _expiryDate,
                        unit: _selectedUnit,
                        threshold: _threshold,
                      );
                    } else {
                      await provider.updateItem(
                        id: widget.item!.id,
                        name: name,
                        quantity: quantity,
                        category: _category,
                        expiryDate: _expiryDate,
                        unit: _selectedUnit,
                        threshold: _threshold,
                      );
                    }
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? 'Save Changes' : 'Save Item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}