import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../widgets/book_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String text) {
    _focusNode.unfocus();
    context.read<BookProvider>().search(text);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BookProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Book Details App')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,focusNode: _focusNode,textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {});
                context.read<BookProvider>().onQueryChanged(value);
              },
              onSubmitted: _submit, decoration: InputDecoration(
                hintText: 'Search books, e.g. Harry Potter',
                prefixIcon: const Icon(Icons.search),suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          context.read<BookProvider>().onQueryChanged('');
                          setState(() {});
                        },
                      ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                _buildBody(p),
                if (p.suggestions.isNotEmpty)
                  Positioned(
                    top: 0, left: 16, right: 16,
                    child: _buildSuggestions(p),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSuggestions(BookProvider p) {
    return Material(
      elevation: 6, borderRadius: BorderRadius.circular(12), clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        shrinkWrap: true, padding: EdgeInsets.zero, physics: const NeverScrollableScrollPhysics(),
        itemCount: p.suggestions.length,
        itemBuilder: (context, i) {
          final book = p.suggestions[i];
          return ListTile(
            dense: true, leading: const Icon(Icons.menu_book_outlined),
            title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(book.authorsText,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () {
              _controller.text = book.title;
              setState(() {});
              _submit(book.title);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(BookProvider p) {
    if (p.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.error != null) {
      return _MessageView(
        icon: Icons.wifi_off, title: 'Something went wrong', message: p.error!, buttonLabel: 'Retry',
        onPressed: () => p.search(p.query),
      );
    }
    if (!p.hasSearched) {
      return const _MessageView(
        icon: Icons.menu_book, title: 'Find your next book', message: 'Search by title, author or keyword.',
      );
    }
    if (p.books.isEmpty) {
      return _MessageView(
        icon: Icons.search_off, title: 'No books found', message: 'Nothing matched "${p.query}". Try a different search.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16), itemCount: p.books.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text('${p.total} results for "${p.query}"'),
          );
        }
        return BookCard(
          book: p.books[i - 1],
          onTap: () {
          },
        );
      },
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