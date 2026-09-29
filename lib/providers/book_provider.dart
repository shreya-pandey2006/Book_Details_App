import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/book_api_service.dart';

class BookProvider extends ChangeNotifier {
  final BookApiService _api = BookApiService();

  static const pageSize = 20;

  // value sent to the API -> label shown to the user
  static const sortOptions = {
    '': 'Relevance',
    'new': 'Newest first',
    'old': 'Oldest first',
    'rating': 'Top rated',
    'editions': 'Most editions',
  };
  static const languageOptions = {
    '': 'Any language',
    'eng': 'English',
    'hin': 'Hindi',
    'spa': 'Spanish',
    'fre': 'French',
    'ger': 'German',
  };

  List<Book> books = [];
  List<Book> suggestions = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasSearched = false;
  String? error;
  String? loadMoreError;
  String query = '';
  int total = 0;
  int _page = 1;

  SearchType searchType = SearchType.all;
  String sort = '';
  String language = '';

  Timer? _debounce;
  int _searchId = 0;
  int _suggestionId = 0;

  bool get hasMore => books.length < total;

  // ---------- filters ----------
  void setSearchType(SearchType type) {
    if (type == searchType) return;
    searchType = type;
    _refreshIfSearched();
  }

  void setSort(String value) {
    if (value == sort) return;
    sort = value;
    _refreshIfSearched();
  }

  void setLanguage(String value) {
    if (value == language) return;
    language = value;
    _refreshIfSearched();
  }

  void _refreshIfSearched() {
    if (hasSearched && query.isNotEmpty) {
      search(query);
    } else {
      notifyListeners();
    }
  }

  // ---------- suggestions ----------
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

  // ---------- search ----------
  Future<void> search(String text, {SearchType? type}) async {
    final q = text.trim();
    if (q.isEmpty) return;
    if (type != null) searchType = type;

    clearSuggestions();
    query = q;
    isLoading = true;
    isLoadingMore = false;
    hasSearched = true;
    error = null;
    loadMoreError = null;
    _page = 1;
    final id = ++_searchId;
    notifyListeners();

    try {
      final result = await _api.search(
        q,
        type: searchType,
        page: 1,
        limit: pageSize,
        sort: sort,
        language: language,
      );
      if (id != _searchId) return;
      books = result.books;
      total = result.total;
    } on ApiException catch (e) {
      if (id != _searchId) return;
      error = e.message;
      books = [];
      total = 0;
    } catch (_) {
      if (id != _searchId) return;
      error = 'Something went wrong. Please try again.';
      books = [];
      total = 0;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore) return;
    isLoadingMore = true;
    loadMoreError = null;
    final id = _searchId;
    notifyListeners();

    try {
      final result = await _api.search(
        query,
        type: searchType,
        page: _page + 1,
        limit: pageSize,
        sort: sort,
        language: language,
      );
      if (id != _searchId) return;
      if (result.books.isEmpty) {
        total = books.length; // nothing more to load
      } else {
        books = [...books, ...result.books];
        _page++;
      }
    } on ApiException catch (e) {
      if (id != _searchId) return;
      loadMoreError = e.message;
    } catch (_) {
      if (id != _searchId) return;
      loadMoreError = 'Could not load more books.';
    }
    isLoadingMore = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}