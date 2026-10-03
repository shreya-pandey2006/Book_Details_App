import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../services/auth_service.dart';
import '../services/book_api_service.dart';
import '../widgets/book_card.dart';
import 'book_details_screen.dart';

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

  void _submit(String text, {SearchType? type}) {
    _focusNode.unfocus();
    context.read<BookProvider>().search(text, type: type);
  }
Future<void> _logout() async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      );
    },
  );

  if (shouldLogout != true) return;

  await AuthService().logout();
}
  String _hint(SearchType type) {
    switch (type) {
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
    final p = context.watch<BookProvider>();
    return Scaffold(
      appBar: AppBar(
  title: const Text('Book Details App'),
  actions: [
    IconButton(
      tooltip: 'Logout',
      icon: const Icon(Icons.logout),
      onPressed: _logout,
    ),
  ],
),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {});
                context.read<BookProvider>().onQueryChanged(value);
              },
              onSubmitted: _submit,
              decoration: InputDecoration(
                hintText: _hint(p.searchType),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
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
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          _buildFilters(p),
          Expanded(
            child: Stack(
              children: [
                _buildBody(p),
                if (p.suggestions.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 16,
                    right: 16,
                    child: _buildSuggestions(p),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFilters(BookProvider p) {
    final provider = context.read<BookProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<SearchType>(
              segments: const [
                ButtonSegment(value: SearchType.all, label: Text('All')),
                ButtonSegment(value: SearchType.title, label: Text('Title')),
                ButtonSegment(value: SearchType.author, label: Text('Author')),
              ],
              selected: {p.searchType},
              onSelectionChanged: (s) => provider.setSearchType(s.first),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  value: p.sort,
                  items: BookProvider.sortOptions,
                  icon: Icons.sort,
                  onChanged: provider.setSort,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown(
                  value: p.language,
                  items: BookProvider.languageOptions,
                  icon: Icons.language,
                  onChanged: provider.setLanguage,
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
        isDense: true,
        prefixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items.entries
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

  Widget _buildSuggestions(BookProvider p) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: p.suggestions.length,
        itemBuilder: (context, i) {
          final book = p.suggestions[i];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(book.authorsText,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () {
              _controller.text = book.title;
              setState(() {});
              _submit(book.title, type: SearchType.title);
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
        icon: Icons.wifi_off,
        title: 'Something went wrong',
        message: p.error!,
        buttonLabel: 'Retry',
        onPressed: () => p.search(p.query),
      );
    }
    if (!p.hasSearched) {
      return const _MessageView(
        icon: Icons.menu_book,
        title: 'Find your next book',
        message: 'Search by title, author or keyword.',
      );
    }
    if (p.books.isEmpty) {
      return _MessageView(
        icon: Icons.search_off,
        title: 'No books found',
        message: 'Nothing matched "${p.query}". Try a different search or filter.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: p.books.length + 2,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text('${p.total} results for "${p.query}"'),
          );
        }
        if (i == p.books.length + 1) {
          return _buildFooter(p);
        }
        return BookCard(
          book: p.books[i - 1],
          onTap: () {
            Navigator.push(
              context,
                MaterialPageRoute(
                  builder: (_) => BookDetailsScreen(
                    book: p.books[i - 1],
                  ),
                ),
             );
            },
        );
      },
    );
  }

  Widget _buildFooter(BookProvider p) {
    if (p.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (p.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(p.loadMoreError!),
            TextButton(onPressed: p.loadMore, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (p.hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: p.loadMore,
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
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}