import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider extends ChangeNotifier {
  static const String _storageKey = 'selected_currency_code';

  CurrencyProvider() {
    _loadCurrency();
  }

  String _currencyCode = 'USD';

  String get currencyCode => _currencyCode;

  // Public map of currency symbols
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CHF': 'CHF',
    'CNY': '¥',
    'INR': '₹',
    'MWK': 'MK',
    'ZAR': 'R',
    'NGN': '₦',
    'GHS': '₵',
    'KES': 'KSh',
    'TZS': 'TSh',
  };

  String get currencySymbol => currencySymbols[_currencyCode] ?? _currencyCode;

  /// Public method to get symbol for any currency code
  static String getSymbol(String code) {
    return currencySymbols[code] ?? code;
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null && currencySymbols.containsKey(saved)) {
      _currencyCode = saved;
      notifyListeners();
    }
  }

  Future<void> setCurrency(String code) async {
    if (!currencySymbols.containsKey(code)) return;
    _currencyCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, code);
    notifyListeners();
  }

  List<String> get availableCurrencies => currencySymbols.keys.toList();
}