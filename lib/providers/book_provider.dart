import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/book_api_service.dart';

class BookProvider extends ChangeNotifier {
  final BookApiService _api = BookApiService();

  List<Book> books = [];
  List<Book> suggestions = [];
  bool isLoading = false;
  bool hasSearched = false;
  String? error;
  String query = '';
  int total = 0;

  Timer? _debounce;
  int _searchId = 0;
  int _suggestionId = 0;

  void onQueryChanged(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.length < 2) {
      _suggestionId++;
      if (suggestions.isNotEmpty) {
        suggestions = [];
        notifyListeners();
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadSuggestions(q);
    });
  }

  Future<void> _loadSuggestions(String q) async {
    final id = ++_suggestionId;
    try {
      final result = await _api.search(q, limit: 5);
      if (id != _suggestionId) return;
      suggestions = result.books;
    } catch (_) {
      if (id != _suggestionId) return;
      suggestions = [];
    }
    notifyListeners();
  }

  void clearSuggestions() {
    _debounce?.cancel();
    _suggestionId++;
    if (suggestions.isNotEmpty) {
      suggestions = [];
      notifyListeners();
    }
  }
  
  Future<void> search(String text) async {
    final q = text.trim();
    if (q.isEmpty) return;

    clearSuggestions();
    query = q;
    isLoading = true;
    hasSearched = true;
    error = null;
    final id = ++_searchId;
    notifyListeners();

    try {
      final result = await _api.search(q, limit: 20);
      if (id != _searchId) return;
      books = result.books;
      total = result.total;
    } on ApiException catch (e) {
      if (id != _searchId) return;
      error = e.message;
      books = [];
    } catch (_) {
      if (id != _searchId) return;
      error = 'Something went wrong. Please try again.';
      books = [];
    }
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}