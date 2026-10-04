import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_api_service.dart';
import '../widgets/book_cover.dart';
class BookDetailsScreen extends StatefulWidget {
  final Book book;
  const BookDetailsScreen({super.key, required this.book});
  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final _api = BookApiService();
  bool _loadingDescription = true;
  String? _description;
  String? _descriptionError;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _loadDescription();
  }

  Future<void> _loadDescription() async {
    setState(() {
      _loadingDescription = true;
      _descriptionError = null;
    });
    try {
      final text = await _api.getDescription(widget.book.key);
      if (!mounted) return;
      setState(() => _description = text);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _descriptionError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _descriptionError = 'Could not load the description.');
    }
    if (!mounted) return;
    setState(() => _loadingDescription = false);
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Book details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: BookCover(
                url: book.coverUrl(size: 'L'),
                width: 160,
                height: 230,
              ),
            ),
            const SizedBox(height: 16),
            Text(book.title,
                style: textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(book.authorsText,
                style: textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            _buildInfoCard(book),
            if (book.subjects.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Subjects', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8,runSpacing: 4, children: book.subjects.map((s) => Chip(label: Text(s))).toList(),),
            ],
            const SizedBox(height: 16),
            Text('Description', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildDescription(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Book book) {
    final rows = <MapEntry<String, String>>[
      if (book.firstPublishYear != null)
        MapEntry('First published', '${book.firstPublishYear}'),
      if (book.pages != null) MapEntry('Pages', '${book.pages}'),
      if (book.publishers.isNotEmpty)
        MapEntry('Publishers', book.publishers.join(', ')),
      if (book.languages.isNotEmpty)
        MapEntry('Languages',
            book.languages.map((l) => l.toUpperCase()).join(', ')),
      if (book.isbn != null) MapEntry('ISBN', book.isbn!),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: rows
              .map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(r.key,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Expanded(child: Text(r.value)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    if (_loadingDescription) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_descriptionError != null) {
      return Row(
        children: [
          Expanded(child: Text(_descriptionError!)),
          TextButton(onPressed: _loadDescription, child: const Text('Retry')),
        ],
      );
    }
    if (_description == null || _description!.trim().isEmpty) {
      return const Text('No description available for this book.');
    }
    final text = _description!.trim();
    final isLong = text.length > 300;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: _expanded || !isLong ? null : 6,
          overflow: _expanded || !isLong ? null : TextOverflow.ellipsis,
        ),
        if (isLong)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Show less' : 'Read more'),
          ),
      ],
    );
  }
}