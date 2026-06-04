import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';   // new

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
  final _pricePerUnitController = TextEditingController();
  final _totalPriceController = TextEditingController();

  // Base categories
  final List<String> _baseCategories = const [
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

  // Base units
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

  // Keyword-based unit detection
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

  late String _selectedCategory;
  String _selectedUnit = 'piece';
  double _threshold = 1.0;
  DateTime _expiryDate = DateTime.now();
  double? _pricePerUnit;
  bool _isUpdatingPrice = false; // prevent recursive listener calls

  @override
  void initState() {
    super.initState();

    // Listen for quantity changes to recalc both fields if needed
    _quantityController.addListener(_onQuantityChanged);
    // Listen for manual changes in price per unit -> compute total
    _pricePerUnitController.addListener(_onUnitPriceChanged);
    // Listen for manual changes in total price -> compute per unit
    _totalPriceController.addListener(_onTotalPriceChanged);

    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _quantityController.text = widget.item!.quantity.toString();
      _selectedCategory = widget.item!.category;
      _selectedUnit = widget.item!.unit;
      _threshold = widget.item!.threshold;
      _expiryDate = widget.item!.expiryDate;
      _pricePerUnit = widget.item!.pricePerUnit;
      if (_pricePerUnit != null) {
        _pricePerUnitController.text = _pricePerUnit!.toString();
      }
    } else {
      _selectedCategory = _baseCategories.first;
      _suggestUnitFromNameAndCategory();
      _nameController.addListener(_onNameChanged);
    }
  }

  @override
  void dispose() {
    if (widget.item == null) {
      _nameController.removeListener(_onNameChanged);
    }
    _quantityController.removeListener(_onQuantityChanged);
    _pricePerUnitController.removeListener(_onUnitPriceChanged);
    _totalPriceController.removeListener(_onTotalPriceChanged);
    _nameController.dispose();
    _quantityController.dispose();
    _pricePerUnitController.dispose();
    _totalPriceController.dispose();
    super.dispose();
  }

  // ---------- helpers ----------

  double _getCurrentQuantity() {
    final q = double.tryParse(_quantityController.text.trim());
    return q ?? 0;
  }

  // When quantity changes, if one price field is filled, recalc the other
  void _onQuantityChanged() {
    if (_isUpdatingPrice) return;
    final qty = _getCurrentQuantity();
    if (qty <= 0) return;

    final unitText = _pricePerUnitController.text.trim();
    final totalText = _totalPriceController.text.trim();

    // Precedence: if total price is filled, recalc unit price
    if (totalText.isNotEmpty) {
      final total = double.tryParse(totalText);
      if (total != null) {
        final ppu = total / qty;
        _isUpdatingPrice = true;
        _pricePerUnit = ppu;
        _pricePerUnitController.text = ppu.toStringAsFixed(4);
        _isUpdatingPrice = false;
        return;
      }
    }
    // If unit price is filled, recalc total price
    if (unitText.isNotEmpty) {
      final ppu = double.tryParse(unitText);
      if (ppu != null) {
        final total = ppu * qty;
        _isUpdatingPrice = true;
        _totalPriceController.text = total.toStringAsFixed(2);
        _isUpdatingPrice = false;
      }
    }
  }

  // Triggered when unit price field is manually changed
  void _onUnitPriceChanged() {
    if (_isUpdatingPrice) return;
    final unitText = _pricePerUnitController.text.trim();
    if (unitText.isEmpty) {
      _pricePerUnit = null;
      if (_totalPriceController.text.isNotEmpty) {
        _totalPriceController.clear();
      }
      return;
    }
    final ppu = double.tryParse(unitText);
    if (ppu == null) return;
    _pricePerUnit = ppu;

    final qty = _getCurrentQuantity();
    if (qty > 0) {
      _isUpdatingPrice = true;
      _totalPriceController.text = (ppu * qty).toStringAsFixed(2);
      _isUpdatingPrice = false;
    } else {
      _isUpdatingPrice = true;
      _totalPriceController.clear();
      _isUpdatingPrice = false;
    }
  }

  // Triggered when total price field is manually changed
  void _onTotalPriceChanged() {
    if (_isUpdatingPrice) return;
    final totalText = _totalPriceController.text.trim();
    if (totalText.isEmpty) {
      return;
    }
    final total = double.tryParse(totalText);
    if (total == null) return;
    final qty = _getCurrentQuantity();
    if (qty <= 0) return;
    final ppu = total / qty;
    _isUpdatingPrice = true;
    _pricePerUnit = ppu;
    _pricePerUnitController.text = ppu.toStringAsFixed(4);
    _isUpdatingPrice = false;
  }

  void _onNameChanged() {
    _suggestUnitFromNameAndCategory();
  }

  void _suggestUnitFromNameAndCategory() {
    final name = _nameController.text.trim().toLowerCase();
    String? suggestedUnit;

    for (final entry in _keywordUnit.entries) {
      if (name.contains(entry.key)) {
        suggestedUnit = entry.value;
        break;
      }
    }

    suggestedUnit ??= _categoryDefaultUnit[_selectedCategory] ?? 'piece';

    if (suggestedUnit != _selectedUnit) {
      setState(() {
        _selectedUnit = suggestedUnit!;
      });
    }
  }

  // ---------- date picker ----------
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

  // ---------- units dropdown ----------
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
        value: '__custom_unit__',
        child: Text('+ Custom unit...', style: TextStyle(color: Colors.teal)),
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

  // ---------- categories dropdown ----------
  List<DropdownMenuItem<String>> _buildCategoryMenuItems() {
    final pantryProvider = Provider.of<PantryProvider>(context, listen: false);
    final customCategories = pantryProvider.customCategories;
    final allCategories = <String>[..._baseCategories];
    for (final cc in customCategories) {
      if (!allCategories.contains(cc)) allCategories.add(cc);
    }
    allCategories.sort();

    final items = allCategories.map((cat) {
      return DropdownMenuItem<String>(
        value: cat,
        child: Text(cat),
      );
    }).toList();

    items.add(
      const DropdownMenuItem<String>(
        value: '__custom_cat__',
        child:
            Text('+ Custom category...', style: TextStyle(color: Colors.teal)),
      ),
    );
    return items;
  }

  Future<void> _showCustomCategoryDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add custom category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., Seafood, Herbs',
            labelText: 'Category name',
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
              final cat = controller.text.trim().toLowerCase();
              if (cat.isNotEmpty) {
                Navigator.pop(ctx, cat);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null) {
      final pantryProvider = Provider.of<PantryProvider>(context, listen: false);
      await pantryProvider.addCustomCategory(result);
      setState(() {
        _selectedCategory = result;
      });
      if (widget.item == null) {
        _suggestUnitFromNameAndCategory();
      }
    }
  }

  // ---------- Build UI ----------
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                    if (value == '__custom_unit__') {
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final parsed = double.tryParse(v.trim());
                    if (parsed != null) _threshold = parsed;
                  },
                  validator: (v) {
                    final parsed = double.tryParse(v?.trim() ?? '');
                    if (parsed == null) return 'Enter a valid number';
                    if (parsed < 0) return 'Threshold cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _buildCategoryMenuItems(),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) async {
                    if (value == '__custom_cat__') {
                      await _showCustomCategoryDialog();
                    } else if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      if (widget.item == null) {
                        _suggestUnitFromNameAndCategory();
                      }
                    }
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Select a category';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ---------- Price section (bidirectional) ----------
                Consumer<CurrencyProvider>(
                  builder: (context, currencyProvider, _) {
                    return TextFormField(
                      controller: _pricePerUnitController,
                      decoration: InputDecoration(
                        labelText:
                            'Price per unit (${currencyProvider.currencySymbol}/$_selectedUnit)',
                        hintText: 'Optional',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v != null &&
                            v.isNotEmpty &&
                            double.tryParse(v) == null) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                Consumer<CurrencyProvider>(
                  builder: (context, currencyProvider, _) {
                    return TextFormField(
                      controller: _totalPriceController,
                      decoration: InputDecoration(
                        labelText:
                            'Total price (${currencyProvider.currencySymbol})',
                        hintText:
                            'Auto‑calculated if per‑unit price entered',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calculate),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v != null &&
                            v.isNotEmpty &&
                            double.tryParse(v) == null) {
                          return 'Enter a valid total price';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Expiry date
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
                    final quantity =
                        double.parse(_quantityController.text.trim());
                    final provider = context.read<PantryProvider>();
                    final expenseProvider = context.read<ExpenseProvider>(); // new

                    // Compute cost for the item being saved
                    final pricePerUnit = _pricePerUnit;
                    final totalCost = pricePerUnit != null
                        ? pricePerUnit * quantity
                        : 0.0;

                    if (widget.item == null) {
                      // New item
                      await provider.addItem(
                        name: name,
                        quantity: quantity,
                        category: _selectedCategory,
                        expiryDate: _expiryDate,
                        unit: _selectedUnit,
                        threshold: _threshold,
                        pricePerUnit: pricePerUnit,
                      );
                      // Record purchase if price was provided
                      if (totalCost > 0) {
                        await expenseProvider.recordPurchase(
                          DateTime.now(),
                          totalCost,
                          _selectedCategory,
                        );
                      }
                    } else {
                      // Existing item: calculate old total cost for adjustment
                      final oldItem = widget.item!;
                      final oldTotalCost = oldItem.pricePerUnit != null
                          ? oldItem.pricePerUnit! * oldItem.quantity
                          : 0.0;

                      await provider.updateItem(
                        id: oldItem.id,
                        name: name,
                        quantity: quantity,
                        category: _selectedCategory,
                        expiryDate: _expiryDate,
                        unit: _selectedUnit,
                        threshold: _threshold,
                        pricePerUnit: pricePerUnit,
                      );

                      // Record adjustment if cost changed
                      final newTotalCost = totalCost;
                      final diff = newTotalCost - oldTotalCost;
                      if (diff != 0) {
                        await expenseProvider.recordAdjustment(
                          DateTime.now(),
                          diff,
                          _selectedCategory,
                        );
                      }
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