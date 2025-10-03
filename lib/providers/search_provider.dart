import 'dart:async';
import 'package:flutter/material.dart';

class SearchProvider extends ChangeNotifier {
  // Core query with debounce
  String _query = '';
  String get query => _query;

  // Filters
  DateTime? _fromDate;
  DateTime? _toDate;
  double? _minAmount;
  double? _maxAmount;
  String? _status; // active, completed, overdue, etc.

  // Search history (simple in-memory; can persist later)
  final List<String> _history = <String>[];
  List<String> get history => List.unmodifiable(_history);

  // Saved filters (by name)
  final Map<String, Map<String, dynamic>> _savedFilters =
      <String, Map<String, dynamic>>{};
  Map<String, Map<String, dynamic>> get savedFilters =>
      Map.unmodifiable(_savedFilters);

  // Debounce
  Timer? _debounceTimer;
  Duration debounceDuration = const Duration(milliseconds: 350);

  void setQuery(String value, {bool addToHistory = false}) {
    _query = value;
    _debounce();
    if (addToHistory && value.trim().isNotEmpty) {
      _addToHistory(value.trim());
    }
  }

  void _addToHistory(String q) {
    _history.remove(q);
    _history.insert(0, q);
    if (_history.length > 10) _history.removeLast();
    notifyListeners();
  }

  void clearQuery() {
    _query = '';
    _debounce();
  }

  // Date range
  void setDateRange(DateTime? from, DateTime? to) {
    _fromDate = from;
    _toDate = to;
    _debounce();
  }

  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;

  // Amount range
  void setAmountRange(double? min, double? max) {
    _minAmount = min;
    _maxAmount = max;
    _debounce();
  }

  double? get minAmount => _minAmount;
  double? get maxAmount => _maxAmount;

  // Status
  void setStatus(String? status) {
    _status = status;
    _debounce();
  }

  String? get status => _status;

  // Save / load filter presets
  void saveFilter(String name) {
    _savedFilters[name] = {
      'query': _query,
      'fromDate': _fromDate,
      'toDate': _toDate,
      'minAmount': _minAmount,
      'maxAmount': _maxAmount,
      'status': _status,
    };
    notifyListeners();
  }

  void loadFilter(String name) {
    final preset = _savedFilters[name];
    if (preset == null) return;
    _query = (preset['query'] as String?) ?? '';
    _fromDate = preset['fromDate'] as DateTime?;
    _toDate = preset['toDate'] as DateTime?;
    _minAmount = preset['minAmount'] as double?;
    _maxAmount = preset['maxAmount'] as double?;
    _status = preset['status'] as String?;
    notifyListeners();
  }

  void clearFilters() {
    _fromDate = null;
    _toDate = null;
    _minAmount = null;
    _maxAmount = null;
    _status = null;
    _debounce();
  }

  void _debounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
