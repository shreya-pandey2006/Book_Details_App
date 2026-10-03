import 'dart:async';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_api_service.dart';
import '../widgets/book_card.dart';
import '../services/auth_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _pageSize = 20;
  static const _sortOptions = {
    '': 'Relevance',
    'new': 'Newest first',
    'old': 'Oldest first',
    'rating': 'Top rated',
    'editions': 'Most editions',
  };
  static const _languageOptions = {
    '': 'Any language',
    'eng': 'English',
    'hin': 'Hindi',
    'spa': 'Spanish',
    'fre': 'French',
    'ger': 'German',
  };

  final _api = BookApiService();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<Book> _books = [];
  List<Book> _suggestions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasSearched = false;
  String? _error;
  String? _loadMoreError;
  String _query = '';
  int _total = 0;
  int _page = 1;
  SearchType _searchType = SearchType.all;
  String _sort = '';
  String _language = '';
  Timer? _debounce;
  int _searchId = 0;
  int _suggestionId = 0;
  bool get _hasMore => _books.length < _total;
  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String text) {
    setState(() {});
    _debounce?.cancel();
    final q = text.trim();
    if (q.length < 2) {
      _clearSuggestions();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _loadSuggestions(q));
  }

  Future<void> _loadSuggestions(String q) async {
    final id = ++_suggestionId;
    List<Book> result;
    try {
      result = (await _api.search(q, limit: 5)).books;
    } catch (_) {
      result = [];
    }
    if (!mounted || id != _suggestionId) return;
    setState(() => _suggestions = result);
  }

  void _clearSuggestions() {
    _debounce?.cancel();
    _suggestionId++;
    if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
  }

  // ---------------- search ----------------
  Future<void> _search(String text, {SearchType? type}) async {
    final q = text.trim();
    if (q.isEmpty) return;
    _focusNode.unfocus();
    _clearSuggestions();

    final id = ++_searchId;
    setState(() {
      if (type != null) _searchType = type;
      _query = q;
      _isLoading = true;
      _isLoadingMore = false;
      _hasSearched = true;
      _error = null;
      _loadMoreError = null;
      _page = 1;
    });

    try {
      final result = await _api.search(
        q,
        type: _searchType, page: 1, limit: _pageSize, sort: _sort, language: _language,
      );
      if (!mounted || id != _searchId) return;
      _books = result.books;
      _total = result.total;
    } on ApiException catch (e) {
      if (!mounted || id != _searchId) return;
      _error = e.message;
      _books = [];
      _total = 0;
    } catch (_) {
      if (!mounted || id != _searchId) return;
      _error = 'Something went wrong. Please try again.';
      _books = [];
      _total = 0;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    final id = _searchId;
    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      final result = await _api.search(
        _query,
        type: _searchType, page: _page + 1, limit: _pageSize, sort: _sort, language: _language,
      );
      if (!mounted || id != _searchId) return;
      if (result.books.isEmpty) {
        _total = _books.length;
      } else {
        _books = [..._books, ...result.books];
        _page++;
      }
    } on ApiException catch (e) {
      if (!mounted || id != _searchId) return;
      _loadMoreError = e.message;
    } catch (_) {
      if (!mounted || id != _searchId) return;
      _loadMoreError = 'Could not load more books.';
    }
    setState(() => _isLoadingMore = false);
  }

  void _refreshIfSearched() {
    if (_hasSearched && _query.isNotEmpty) {
      _search(_query);
    } else {
      setState(() {});
    }
  }
  String _hint() {
    switch (_searchType) {
      case SearchType.title:
        return 'Book title, e.g. The Hobbit';
      case SearchType.author:
        return 'Author name, e.g. J.K. Rowling';
      case SearchType.all:
        return 'Search books, e.g. Harry Potter';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: const Text('Book Details App'),
  actions: [
    IconButton( icon: const Icon(Icons.logout), tooltip: 'Sign out', onPressed: () => AuthService().signOut(),
    ),
  ],
),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller, focusNode: _focusNode, textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged, onSubmitted: _search,
              decoration: InputDecoration(
                hintText: _hint(),
                prefixIcon: const Icon(Icons.search), suffixIcon: _controller.text.isEmpty ? null : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                      ),
                filled: true,
                border: OutlineInputBorder( borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          _buildFilters(),
          Expanded(
            child: Stack(
              children: [
                _buildBody(),
                if (_suggestions.isNotEmpty)
                  Positioned(
                    top: 0, left: 16, right: 16, child: _buildSuggestions(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          SizedBox( width: double.infinity,
            child: SegmentedButton<SearchType>(
              segments: const [
                ButtonSegment(value: SearchType.all, label: Text('All')),
                ButtonSegment(value: SearchType.title, label: Text('Title')),
                ButtonSegment(value: SearchType.author, label: Text('Author')),
              ],
              selected: {_searchType},
              onSelectionChanged: (s) {
                _searchType = s.first;
                _refreshIfSearched();
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                   value: _sort, items: _sortOptions, icon: Icons.sort,
                  onChanged: (v) {
                    _sort = v;
                    _refreshIfSearched();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown(
                  value: _language, items: _languageOptions, icon: Icons.language,
                  onChanged: (v) {
                    _language = v;
                    _refreshIfSearched();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required Map<String, String> items,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        isDense: true, prefixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true, isDense: true, items: items.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Material(
      elevation: 6, borderRadius: BorderRadius.circular(12), clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        shrinkWrap: true, padding: EdgeInsets.zero, physics: const NeverScrollableScrollPhysics(), itemCount: _suggestions.length,
        itemBuilder: (context, i) {
          final book = _suggestions[i];
          return ListTile(
            dense: true, leading: const Icon(Icons.menu_book_outlined),
            title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(book.authorsText, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () {
              _controller.text = book.title;
              _search(book.title, type: SearchType.title);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _MessageView(
        icon: Icons.wifi_off, title: 'Something went wrong', message: _error!, buttonLabel: 'Retry',
        onPressed: () => _search(_query),
      );
    }
    if (!_hasSearched) {
      return const _MessageView(
        icon: Icons.menu_book, title: 'Find your next book', message: 'Search by title, author or keyword.',
      );
    }
    if (_books.isEmpty) {
      return _MessageView(
        icon: Icons.search_off, title: 'No books found', message: 'Nothing matched "$_query". Try a different search or filter.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16), itemCount: _books.length + 2, 
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text('$_total results for "$_query"'),
          );
        }
        if (i == _books.length + 1) return _buildFooter();
        return BookCard(
          book: _books[i - 1],
          onTap: () {
          },
        );
      },
    );
  }

  Widget _buildFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_loadMoreError!), TextButton(onPressed: _loadMore, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: _loadMore, icon: const Icon(Icons.expand_more), label: const Text('Load more'),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16), child: Center(child: Text('You have reached the end.')),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (buttonLabel != null) ...[
              const SizedBox(height: 16), FilledButton(onPressed: onPressed, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
