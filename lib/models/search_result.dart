import 'book.dart';

class SearchResult {
  final List<Book> books;
  final int total;

  SearchResult({required this.books, required this.total});
}