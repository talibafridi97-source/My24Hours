import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/debtor_model.dart';
import '../models/transaction_model.dart';

/// Provider class handling state management for debtors, transactions, and business settings.
class KhaataProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _prefBusinessNameKey = 'business_name';

  String _businessName = 'My Business Khata';
  String _searchQuery = '';
  bool _isLoading = false;

  List<Debtor> _debtors = [];
  List<Debtor> _filteredDebtors = [];

  Debtor? _currentDebtor;
  List<TransactionModel> _currentDebtorTransactions = [];

  // Getters
  String get businessName => _businessName;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  List<Debtor> get debtors => _debtors;
  List<Debtor> get filteredDebtors => _filteredDebtors;
  Debtor? get currentDebtor => _currentDebtor;
  List<TransactionModel> get currentDebtorTransactions => _currentDebtorTransactions;

  /// Calculate total amount to collect (sum of positive running balances)
  double get totalReceivable {
    return _debtors
        .where((d) => d.netBalance > 0)
        .fold(0.0, (sum, d) => sum + d.netBalance);
  }

  /// Calculate total amount to give back (sum of negative running balances)
  double get totalPayable {
    return _debtors
        .where((d) => d.netBalance < 0)
        .fold(0.0, (sum, d) => sum + d.netBalance.abs());
  }

  /// Initialize provider state
  Future<void> init() async {
    _setLoading(true);
    await _loadBusinessName();
    await loadDebtors();
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Load Business/Profile name from SharedPreferences
  Future<void> _loadBusinessName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _businessName = prefs.getString(_prefBusinessNameKey) ?? 'My Business Khata';
    } catch (e) {
      debugPrint('Error loading business name: $e');
    }
  }

  /// Update Business/Profile name
  Future<void> setBusinessName(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    _businessName = trimmedName;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefBusinessNameKey, _businessName);
    } catch (e) {
      debugPrint('Error saving business name: $e');
    }
  }

  /// Load all debtors with computed balances from SQLite
  Future<void> loadDebtors() async {
    try {
      _debtors = await _dbHelper.getDebtorsWithBalances();
      _applySearchFilter();
    } catch (e) {
      debugPrint('Error loading debtors: $e');
    }
    notifyListeners();
  }

  /// Set search query and update filtered list in real-time
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applySearchFilter();
    notifyListeners();
  }

  /// Apply real-time search filtering on debtors list
  void _applySearchFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredDebtors = List.from(_debtors);
    } else {
      final query = _searchQuery.toLowerCase().trim();
      _filteredDebtors = _debtors.where((debtor) {
        final nameMatch = debtor.name.toLowerCase().contains(query);
        final phoneMatch = debtor.phone.contains(query);
        return nameMatch || phoneMatch;
      }).toList();
    }
  }

  /// Add a new debtor (Kharzdaar)
  Future<bool> addDebtor(String name, String phone) async {
    try {
      final newDebtor = Debtor(
        name: name.trim(),
        phone: phone.trim(),
        createdAt: DateTime.now(),
      );
      final id = await _dbHelper.insertDebtor(newDebtor);
      if (id > 0) {
        await loadDebtors();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding debtor: $e');
    }
    return false;
  }

  /// Update debtor information
  Future<bool> updateDebtor(Debtor debtor) async {
    try {
      final count = await _dbHelper.updateDebtor(debtor);
      if (count > 0) {
        await loadDebtors();
        if (_currentDebtor?.id == debtor.id) {
          _currentDebtor = await _dbHelper.getDebtorById(debtor.id!);
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error updating debtor: $e');
    }
    return false;
  }

  /// Delete a debtor and all their transactions
  Future<bool> deleteDebtor(int debtorId) async {
    try {
      final count = await _dbHelper.deleteDebtor(debtorId);
      if (count > 0) {
        if (_currentDebtor?.id == debtorId) {
          _currentDebtor = null;
          _currentDebtorTransactions = [];
        }
        await loadDebtors();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting debtor: $e');
    }
    return false;
  }

  /// Load detail view for a debtor and their transaction history
  Future<void> loadDebtorDetail(int debtorId) async {
    _setLoading(true);
    try {
      _currentDebtor = await _dbHelper.getDebtorById(debtorId);
      _currentDebtorTransactions = await _dbHelper.getTransactionsForDebtor(debtorId);
    } catch (e) {
      debugPrint('Error loading debtor detail: $e');
    }
    _setLoading(false);
  }

  /// Add a ledger transaction for current debtor
  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      final id = await _dbHelper.insertTransaction(transaction);
      if (id > 0) {
        await loadDebtorDetail(transaction.debtorId);
        await loadDebtors();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
    return false;
  }

  /// Delete a transaction
  Future<bool> deleteTransaction(int transactionId, int debtorId) async {
    try {
      final count = await _dbHelper.deleteTransaction(transactionId);
      if (count > 0) {
        await loadDebtorDetail(debtorId);
        await loadDebtors();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
    }
    return false;
  }
}
