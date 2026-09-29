import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_api_service.dart';
import '../widgets/book_cover.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;

  const BookDetailsScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final BookApiService _api = BookApiService();

  String? _description;
  bool _isLoadingDescription = true;
  String? _descriptionError;

  @override
  void initState() {
    super.initState();
    _loadDescription();
  }

  Future<void> _loadDescription() async {
    try {
      final description = await _api.getDescription(widget.book.key);

      if (!mounted) return;

      setState(() {
        _description = description;
        _isLoadingDescription = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _descriptionError = e.message;
        _isLoadingDescription = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _descriptionError = 'Could not load the description.';
        _isLoadingDescription = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover + basic information
            Center(
              child: BookCover(
                url: book.coverUrl(size: 'L'),
                width: 180,
                height: 270,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              book.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              book.authorsText,
              style: theme.textTheme.titleMedium,
            ),

            const SizedBox(height: 20),

            // Publication information
            _sectionTitle(context, 'Publication Details'),

            const SizedBox(height: 10),

            _infoRow(
              context,
              Icons.calendar_today,
              'First published',
              book.firstPublishYear?.toString() ?? 'Unknown',
            ),

            _infoRow(
              context,
              Icons.business,
              'Publisher',
              book.publishers.isEmpty
                  ? 'Unknown'
                  : book.publishers.join(', '),
            ),

            _infoRow(
              context,
              Icons.menu_book,
              'Pages',
              book.pages?.toString() ?? 'Unknown',
            ),

            _infoRow(
              context,
              Icons.language,
              'Language',
              book.languages.isEmpty
                  ? 'Unknown'
                  : book.languages.join(', '),
            ),

            if (book.isbn != null)
              _infoRow(
                context,
                Icons.numbers,
                'ISBN',
                book.isbn!,
              ),

            const SizedBox(height: 24),

            // Description
            _sectionTitle(context, 'Description'),

            const SizedBox(height: 10),

            _buildDescription(context),

            const SizedBox(height: 24),

            // Subjects
            if (book.subjects.isNotEmpty) ...[
              _sectionTitle(context, 'Subjects'),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: book.subjects.take(15).map((subject) {
                  return Chip(
                    label: Text(subject),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    if (_isLoadingDescription) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_descriptionError != null) {
      return Text(
        _descriptionError!,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }

    if (_description == null || _description!.trim().isEmpty) {
      return Text(
        'No description available for this book.',
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    return Text(
      _description!,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: 1.5,
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}