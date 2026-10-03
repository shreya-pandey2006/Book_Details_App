import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task2/models/book.dart';
import 'package:task2/widgets/book_card.dart';

void main() {
  test('Book.fromSearchJson reads the main fields', () {
    final book = Book.fromSearchJson({
      'key': '/works/OL1W',
      'title': 'Test Book',
      'author_name': ['Jane Doe'],
      'first_publish_year': 1999,
      'cover_i': 123,
      'subject': ['Fantasy', 'Magic'],
    });

    expect(book.title, 'Test Book');
    expect(book.authorsText, 'Jane Doe');
    expect(book.firstPublishYear, 1999);
    expect(book.coverUrl(), 'https://covers.openlibrary.org/b/id/123-L.jpg');
    expect(book.subjects, ['Fantasy', 'Magic']);
  });

  test('Book falls back when data is missing', () {
    final book = Book.fromSearchJson({'key': '/works/OL2W'});

    expect(book.title, 'Untitled');
    expect(book.authorsText, 'Unknown author');
    expect(book.coverUrl(), isNull);
  });

  testWidgets('BookCard shows title, author and year', (tester) async {
    final book = Book(
      key: '/works/OL1W',
      title: 'Test Book',
      authors: const ['Jane Doe'],
      firstPublishYear: 1999,
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: BookCard(book: book))),
    );

    expect(find.text('Test Book'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('First published 1999'), findsOneWidget);
  });
}
