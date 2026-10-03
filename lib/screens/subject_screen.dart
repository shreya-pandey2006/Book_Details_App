import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_api_service.dart';
import '../widgets/book_card.dart';
import 'book_details_screen.dart';
class SubjectScreen extends StatefulWidget {
  final String subject;
  const SubjectScreen({super.key, required this.subject});
  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  static const _pageSize = 20;
  final _api = BookApiService();

  List<Book> _books = [];
  int _total = 0;
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _loadMoreError;

  bool get _hasMore => _books.length < _total;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
    });
    try {
      final result = await _api.getSubject(widget.subject, page: 1, limit: _pageSize);
      if (!mounted) return;
      _books = result.books;
      _total = result.total;
    } on ApiException catch (e) {
      if (!mounted) return;
      _error = e.message;
    } catch (_) {
      if (!mounted) return;
      _error = 'Something went wrong. Please try again.';
    }
    setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final result = await _api.getSubject(widget.subject,
          page: _page + 1, limit: _pageSize);
      if (!mounted) return;
      if (result.books.isEmpty) {
        _total = _books.length;
      } else {
        _books = [..._books, ...result.books];
        _page++;
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _loadMoreError = e.message;
    } catch (_) {
      if (!mounted) return;
      _loadMoreError = 'Could not load more books.';
    }
    setState(() => _loadingMore = false);
  }

  String get _title {
    final s = widget.subject.trim();
    return s.isEmpty ? 'Subject' : s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_books.isEmpty) {
      return const Center(child: Text('No books found for this subject.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: _books.length + 1,
      itemBuilder: (context, i) {
        if (i == _books.length) return _buildFooter();
        final book = _books[i];
        return BookCard(
          book: book,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_loadMoreError!),
            TextButton(onPressed: _loadMore, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: _loadMore,
            icon: const Icon(Icons.expand_more),
            label: const Text('Load more'),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: Text('You have reached the end.')),
    );
  }
}